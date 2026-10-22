# D http client benchmark

This repository contains a HTTP client implementation for comparing the client's performance with implementations in other programming languages such as D, Rust and Go.

### Prerequisites

- D, Rust, Go, Python, R, C++, Swift, Zig
- [`matplotlib`](https://matplotlib.org/) (for plotting)

### Results

All results are published on the [`output`](https://github.com/cyrusmsk/d_http_client_benchmark/tree/output) branch.

Python clients:

![python](https://raw.githubusercontent.com/cyrusmsk/d_http_client_benchmark/output/benchmarks-python.png)

R clients:

![r](https://raw.githubusercontent.com/cyrusmsk/d_http_client_benchmark/output/benchmarks-r.png)

Other languages (D, Go, Rust, C#, C++, Swift, Zig):

![rest](https://raw.githubusercontent.com/cyrusmsk/d_http_client_benchmark/output/benchmarks-rest.png)

Full comparison of all clients in a single plot: [benchmarks.png](https://raw.githubusercontent.com/cyrusmsk/d_http_client_benchmark/output/benchmarks.png)

### Benchmarking

To run the benchmarks:

```sh
chmod +x bench.sh
./bench.sh
```

The suite is split into separate tests and the result is saved to `benchmarks.json`. Set `BENCH_SCALE=0` for a fast smoke run:

```sh
BENCH_SCALE=0 ./bench.sh
```

Clients honor these environment variables:

- `BENCH_PATH` — endpoint path, default `/ping`
- `BENCH_COUNT` — number of requests, default `5000`
- `BENCH_CONCURRENCY` — in-flight requests, default `1`

### Server endpoints

The server exposes benchmark endpoints used by the suite:

| Endpoint | Response | Purpose |
|---|---:|---|
| `/ping` | `OK` | Warm keep-alive overhead |
| `/json` | ~1 KiB JSON | JSON parsing overhead |
| `/download` | 64 KiB binary | Body throughput |
| `/large?size=1048576` | 1 MiB binary | Large response throughput |
| `/delay?ms=10` | `OK` after delay | Latency/concurrency behavior |
| `/echo` | request body | Upload handling |
| `/status/404` | HTTP 404 | Error status handling |
| `/status/500` | HTTP 500 | Server error handling |

### Plotting

Results are stored in `benchmarks.json`, `benchmarks-python.json`, `benchmarks-r.json`, and `benchmarks-rest.json`.

Plots are stacked bars:

- x-axis: HTTP client solution
- bar segments: benchmark test
- y-axis: elapsed seconds

To render all plots:

```sh
python plot_whisker.py benchmarks.json -o benchmarks.png
python plot_whisker.py benchmarks-python.json -o benchmarks-python.png
python plot_whisker.py benchmarks-r.json -o benchmarks-r.png
python plot_whisker.py benchmarks-rest.json -o benchmarks-rest.png
```

The workflow generates the overall plot plus separate `python`, `r`, and `rest` plots.

### TODO
Add:

[x] httpx Python

[x] httr(2) R

### Environment

The results are coming from a GitHub runner (`ubuntu-latest`) and automated with [this workflow](https://github.com/cyrusmsk/d_http_client_benchmark/blob/master/.github/workflows/benchmark.yml).

To see the output for the latest run, check out the [`output`](https://github.com/cyrusmsk/d_http_client_benchmark/tree/output) branch in this repository.

### Credits

[`zig-http-benchmarks`](https://github.com/orhun/zig-http-benchmarks) - initial implementation mostly related to Zig language, which was adopted and adjusted for better time measurements (github repo)

[`http-clients-benchmark`](https://gitlab.com/os85/http-clients-benchmark) - benchmark ideas for HTTP clients testing in Ruby (gitlab repo)

[`rust clients test`](https://shnatsel.medium.com/smoke-testing-rust-http-clients-b8f2ee5db4e6) - some details about HTTP clients and CURL problems (Medium article, 2020)

[`python clients test`](https://github.com/perodriguezl/python-http-libraries-benchmark) - some python clients testing including RPS, handshake, throughput (github repo)
### License

<sup>
Licensed under <a href="LICENSE">The MIT License</a>.
</sup>
