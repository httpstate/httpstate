// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

package httpstate

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

func Get(uuid string) *string {
	url := fmt.Sprintf("https://httpstate.com/%s", uuid)

	resp, err := http.Get(url)
	if err != nil {
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil
	}

	s := string(body)
	return &s
}

func Read(uuid string) *string {
	return Get(uuid)
}

func Set(uuid string, data string) *int {
	url := fmt.Sprintf("https://httpstate.com/%s", uuid)

	resp, err := http.Post(url, "text/plain;charset=UTF-8", bytes.NewBufferString(data))
	if err != nil {
		return nil
	}
	defer resp.Body.Close()

	statusCode := resp.StatusCode
	return &statusCode
}

func Write(uuid string, data string) *int {
	return Set(uuid, data)
}

// HTTP State
type HttpStateCallback func(data *string)

type HttpState struct {
	Data *string
	ET map[string][]HttpStateCallback
	UUID string
	WS *websocket.Conn
}

func New(uuid string) *HttpState {
	hs := &HttpState{
		Data:nil,
		ET:make(map[string][]HttpStateCallback),
		UUID:uuid,
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

func (hs *HttpState) Get() *string {
	return Get(hs.UUID)
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

func (hs *HttpState) Read() *string {
	return Read(hs.UUID)
}

func (hs *HttpState) Set(data string) *int {
	return Set(hs.UUID, data)
}

func (hs *HttpState) Write(data string) *int {
	return Write(hs.UUID, data)
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

	ping := time.NewTicker(time.Second*30) // 30 SECONDS
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
		_, message, err := c.ReadMessage()
		if err != nil {
			fmt.Println("err:", err)

			close(pingClose)

			return
		}

		s := string(message)
		hs.Data = &s

		if
			hs.Data != nil &&
			len(*hs.Data) > 32 &&
			(*hs.Data)[:32] == hs.UUID &&
			(*hs.Data)[45] == '1' {
			data := (*hs.Data)[46:]

			hs.Emit("change", &data)
		}
	}
}
