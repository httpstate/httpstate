// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

package httpstate

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

type GetArgs struct {
	Authorization string
}

type GetResult struct {
	Data         string
	ETag         string
	LastModified string
}

type SetArgs struct {
	Authorization string
}

func Get(uuid string, args *GetArgs) (*GetResult, error) {
	url := fmt.Sprintf("https://httpstate.com/%s", uuid)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Println(time.Now().Format(time.RFC3339), "get.error", err)

		return nil, err
	}

	if args != nil && args.Authorization != "" {
		req.Header.Set("Authorization", args.Authorization)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println(time.Now().Format(time.RFC3339), "get.error", err)

		return nil, err
	}
	defer resp.Body.Close()

	switch resp.StatusCode {
	case http.StatusOK:
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			fmt.Println(time.Now().Format(time.RFC3339), "get.error", err)

			return nil, err
		}

		result := &GetResult{
			Data:         string(body),
			ETag:         resp.Header.Get("ETag"),
			LastModified: resp.Header.Get("Last-Modified"),
		}

		return result, nil
	case http.StatusUnauthorized:
		return nil, fmt.Errorf("401 Unauthorized")
	case http.StatusNotFound:
		return nil, fmt.Errorf("404 Not Found")
	case http.StatusTooManyRequests:
		return nil, fmt.Errorf("429 Too Many Requests")
	}

	return nil, nil
}

var Message = struct {
	Unpack func(b []byte) *HttpStateMessageType
}{Unpack: func(b []byte) *HttpStateMessageType {
	var header int = int(b[0])

	if header == 0 {
		var length int = int(b[1])

		return &HttpStateMessageType{
			UUID:      string(b[2 : 2+length]),
			Timestamp: binary.BigEndian.Uint64(b[2+length : 2+length+8]),
			Type:      b[2+length+8],
			Value:     b[2+length+9:],
		}
	}

	return nil
}}

func Post(uuid string, data string, args *SetArgs) (int, error) {
	return Set(uuid, data, args)
}

func Put(uuid string, data string, args *SetArgs) (int, error) {
	return Set(uuid, data, args)
}

func Read(uuid string, args *GetArgs) (*GetResult, error) {
	return Get(uuid, args)
}

func Set(uuid string, data string, args *SetArgs) (int, error) {
	url := fmt.Sprintf("https://httpstate.com/%s", uuid)

	req, err := http.NewRequest("POST", url, bytes.NewBufferString(data))
	if err != nil {
		fmt.Println(time.Now().Format(time.RFC3339), "set.error", err)

		return 0, err
	}

	req.Header.Set("Content-Type", "text/plain;charset=UTF-8")

	if args != nil && args.Authorization != "" {
		req.Header.Set("Authorization", args.Authorization)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println(time.Now().Format(time.RFC3339), "set.error", err)

		return 0, err
	}
	defer resp.Body.Close()

	switch resp.StatusCode {
	case http.StatusUnauthorized:
		return 0, fmt.Errorf("401 Unauthorized")
	case http.StatusNotFound:
		return 0, fmt.Errorf("404 Not Found")
	case http.StatusRequestEntityTooLarge:
		return 0, fmt.Errorf("413 Content Too Large")
	}

	return resp.StatusCode, nil
}

func Write(uuid string, data string, args *SetArgs) (int, error) {
	return Set(uuid, data, args)
}

// HTTPState
type HttpState struct {
	Data *string
	ET   map[string][]HttpStateCallback
	UUID string
	WS   *websocket.Conn
}

type HttpStateCallback func(data *string)

type HttpStateMessageType struct {
	UUID      string
	Timestamp uint64
	Type      uint8
	Value     []byte
}

func New(uuid string) *HttpState {
	hs := &HttpState{
		Data: nil,
		ET:   make(map[string][]HttpStateCallback),
		UUID: uuid,
	}

	go hs.ws()

	return hs
}

func (hs *HttpState) Emit(_type string, data *string) *HttpState {
	if callbacks, ok := hs.ET[_type]; ok {
		for _, callback := range callbacks {
			callback(data)
		}
	}

	return hs
}

func (hs *HttpState) Get() *GetResult {
	result, err := Get(hs.UUID, nil)

	if err != nil || result == nil {
		return nil
	}

	hs.Data = &result.Data

	return result
}

func (hs *HttpState) Off(_type string, _callback HttpStateCallback) *HttpState {
	if callbacks, ok := hs.ET[_type]; ok {
		for i, callback := range callbacks {
			if fmt.Sprintf("%p", callback) == fmt.Sprintf("%p", _callback) {
				hs.ET[_type] = append(callbacks[:i], callbacks[i+1:]...)

				break
			}
		}

		if len(hs.ET[_type]) == 0 {
			delete(hs.ET, _type)
		}
	}

	return hs
}

func (hs *HttpState) On(_type string, _callback HttpStateCallback) *HttpState {
	hs.ET[_type] = append(hs.ET[_type], _callback)

	return hs
}

func (hs *HttpState) Post(data string) *int {
	return hs.Set(data)
}

func (hs *HttpState) Put(data string) *int {
	return hs.Set(data)
}

func (hs *HttpState) Read() *GetResult {
	return hs.Get()
}

func (hs *HttpState) Set(data string) *int {
	statusCode, err := Set(hs.UUID, data, nil)

	if err != nil {
		return nil
	}

	return &statusCode
}

func (hs *HttpState) Write(data string) *int {
	return hs.Set(data)
}

func (hs *HttpState) ws() {
	url := fmt.Sprintf("wss://httpstate.com/%s", hs.UUID)

	c, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		fmt.Println("err:", err)

		return
	}
	defer c.Close()

	hs.WS = c

	if err := hs.WS.WriteMessage(websocket.TextMessage, []byte(fmt.Sprintf(`{"open":"%s"}`, hs.UUID))); err != nil {
		fmt.Println("err:", err)

		return
	}

	ping := time.NewTicker(time.Second * 30) // 30 SECONDS
	defer ping.Stop()

	pingClose := make(chan struct{})

	go func() {
		for {
			select {
			case <-ping.C:
				if err := c.WriteMessage(websocket.PingMessage, nil); err != nil {
					fmt.Println("err:", err)

					close(pingClose)

					return
				}
			case <-pingClose:
				return
			}
		}
	}()

	for {
		_, _data, err := c.ReadMessage()
		if err != nil {
			fmt.Println("err:", err)

			close(pingClose)

			return
		}

		var data *HttpStateMessageType = Message.Unpack(_data)

		if data != nil && data.UUID == hs.UUID && data.Type == 1 {
			var s string = string(data.Value)
			hs.Data = &s

			hs.Emit("change", hs.Data)
		}
	}
}
