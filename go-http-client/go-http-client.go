package main

import (
	"fmt"
	"strconv"
	"io/ioutil"
	"net"
	"net/http"
	"time"
)

func main() {
	dialer := &net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}
	transport := &http.Transport{
		DialContext: dialer.DialContext,
	}
	client := &http.Client{
		Transport: transport,
	}

    var result = 0
	for i := 0; i < 5000; i++ {
		req, err := http.NewRequest(http.MethodGet, "http://127.0.0.1:8000/get", nil)
		if err != nil {
			fmt.Println("Error creating GET request:", err)
			return
		}

		req.Header.Add("Connection", "keep-alive")

		resp, err := client.Do(req)
		if err != nil {
			fmt.Println("Error sending GET request:", err)
			return
		}
		defer resp.Body.Close()

		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Println("Error reading response:", err)
			return
		}
        data, err := strconv.Atoi(string(body))
		if err != nil {
			fmt.Println("Error parsing int:", err)
			return
		}
       	result += data
	}
	fmt.Println(result)
}
