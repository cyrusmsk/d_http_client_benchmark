package main

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"strconv"
	"sync"
	"time"
)

func envInt(name string, fallback int) int {
	if v, ok := os.LookupEnv(name); ok {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

func main() {
	path := os.Getenv("BENCH_PATH")
	if path == "" {
		path = "/ping"
	}
	url := "http://127.0.0.1:8000" + path
	total := envInt("BENCH_COUNT", 5000)
	concurrency := envInt("BENCH_CONCURRENCY", 1)
	if concurrency < 1 {
		concurrency = 1
	}

	dialer := &net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}
	transport := &http.Transport{
		DialContext:         dialer.DialContext,
		MaxConnsPerHost:     concurrency,
		MaxIdleConns:        concurrency,
		MaxIdleConnsPerHost: concurrency,
	}
	client := &http.Client{
		Transport: transport,
	}

	var result int64
	var wg sync.WaitGroup
	var mu sync.Mutex
	sem := make(chan struct{}, concurrency)

	for i := 0; i < total; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			req, err := http.NewRequest(http.MethodGet, url, nil)
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
			body, err := ioutil.ReadAll(resp.Body)
			resp.Body.Close()
			if err != nil {
				fmt.Println("Error reading response:", err)
				return
			}

			mu.Lock()
			result += int64(len(body))
			mu.Unlock()
		}()
	}

	wg.Wait()
	fmt.Println(result)
}
