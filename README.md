# D http client benchmark

This repository contains a HTTP client implementation for comparing the client's performance with implementations in other programming languages such as D, Rust and Go.

### Prerequisites

- D, Rust, Go, Python, R
- [Hyperfine](https://github.com/sharkdp/hyperfine) (for benchmarking)

### Results

![plot_whisker](https://raw.githubusercontent.com/cyrusmsk/d_http_client_benchmark/output/benchmarks.png)

Results in a [table](https://raw.githubusercontent.com/cyrusmsk/d_http_client_benchmark/output/benchmarks.md)

### Benchmarking

To run the benchmarks:

```sh
chmod +x bench.sh
./bench.sh
```

The result will be saved to `benchmarks.md` and `benchmarks.json`.

### Plotting

Use the [JSON data](https://github.com/sharkdp/hyperfine#json) along with the [scripts](https://github.com/sharkdp/hyperfine/tree/master/scripts) from the `hyperfine` examples to plot data using [`matplotlib`](https://matplotlib.org/). For example:

```sh
git clone --depth 1 https://github.com/sharkdp/hyperfine
python hyperfine/scripts/plot_whisker.py benchmarks.json
```

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
