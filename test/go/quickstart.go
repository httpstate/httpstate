// go get github.com/httpstate/httpstate/go@latest

package main

import (
	"fmt"
	"time"

	"github.com/httpstate/httpstate/go"
)

func main() {
	fmt.Println("main")

  hs := httpstate.New("58bff2fcbeb846958f36e7ae5b8a75b0")

	hs.On("change", func(data *string) {
		if data != nil {
			fmt.Println(time.Now().UTC().Format(time.RFC3339), "data", *data)
		}
	})

	// Not needed per se, only meant to keep the script alive
	select {}
}
