## `d_http_clint_benchmark`

This repository contains a HTTP client implementation for comparing the client's performance with implementations in other programming languages such as D, Rust and Go.

### Prerequisites

- D, Rust/Cargo, Go, Python
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
Examples of the output below:
```
  rust-hyper ran
    1.01 ± 0.02 times faster than rust-ureq
    1.01 ± 0.02 times faster than rust-reqwest
    1.24 ± 0.06 times faster than go-http-client
    1.46 ± 0.05 times faster than rust-attohttpc
    2.03 ± 0.05 times faster than zig-http-client
    4.26 ± 0.12 times faster than curl
    8.57 ± 0.12 times faster than python-http-client
   19.93 ± 0.25 times faster than cpp-asio-httpclient
```

| Command               |    Mean [ms] | Min [ms] | Max [ms] |     Relative |
| :-------------------- | -----------: | -------: | -------: | -----------: |
| `curl`                | 457.9 ± 11.2 |    442.4 |    522.2 |  4.26 ± 0.12 |
| `zig-http-client`     |  218.5 ± 4.8 |    210.3 |    240.3 |  2.03 ± 0.05 |
| `rust-attohttpc`      |  157.2 ± 5.3 |    151.8 |    190.4 |  1.46 ± 0.05 |
| `rust-hyper`          |  107.6 ± 1.3 |    104.4 |    114.8 |         1.00 |
| `rust-reqwest`        |  108.7 ± 2.2 |    105.4 |    123.7 |  1.01 ± 0.02 |
| `rust-ureq`           |  108.4 ± 2.3 |    105.7 |    123.1 |  1.01 ± 0.02 |
| `go-http-client`      |  133.1 ± 6.2 |    127.6 |    159.2 |  1.24 ± 0.06 |
| `python-requests`     |  921.9 ± 5.9 |    911.4 |    947.1 |  8.57 ± 0.12 |

### Plotting

Use the [JSON data](https://github.com/sharkdp/hyperfine#json) along with the [scripts](https://github.com/sharkdp/hyperfine/tree/master/scripts) from the `hyperfine` examples to plot data using [`matplotlib`](https://matplotlib.org/). For example:

```sh
git clone --depth 1 https://github.com/sharkdp/hyperfine
python hyperfine/scripts/plot_whisker.py benchmarks.json
```

### Environment

The results are coming from a GitHub runner (`ubuntu-latest`) and automated with [this workflow](https://github.com/cyrusmsk/d_http_client_benchmark/blob/master/.github/workflows/benchmark.yml).

To see the output for the latest run, check out the [`output`](https://github.com/cyrusmsk/d_http_client_benchmark/tree/output) branch in this repository.

### Credits

[`zig-http-benchmarks`](https://github.com/orhun/zig-http-benchmarks) - initial implementation mostly related to Zig language, which was adopted and adjusted for better time measurements.

### License

<sup>
Licensed under <a href="LICENSE">The MIT License</a>.
</sup>
