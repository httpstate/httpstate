// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

// go mod init quickstart
// go get github.com/httpstate/httpstate/go@latest

package main

import (
	"fmt"
	"time"

	"github.com/httpstate/httpstate/go"
)

func main() {
	httpstate.New("58bff2fcbeb846958f36e7ae5b8a75b0", nil).On("change", func(result *httpstate.GetResult) {
		if result != nil {
			fmt.Println(time.Now().UTC().Format(time.RFC3339), "data", result.Data)
		}
	})

	// Not needed per se, only meant to keep the script alive
	select {}
}
