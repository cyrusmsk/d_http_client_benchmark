#!/usr/bin/env bash

cpwd="$(pwd)"
required_bins=('cargo' 'go' 'python' 'hyperfine')
rust_bins=('rust-http-server' 'rust-attohttpc' 'rust-hyper' 'rust-reqwest' 'rust-ureq')
go_bins=('go-http-client')
python_bins=('python-requests', 'python-urllib3')

for required_bin in "${required_bins[@]}"; do
  if ! command -v "${required_bin}" &>/dev/null; then
    echo "$required_bin is not installed!"
    exit 1
  fi
done

for rust_bin in "${rust_bins[@]}"; do
  echo "Building ${rust_bin}..."
  cargo build --release --manifest-path "${cpwd}/${rust_bin}/Cargo.toml"
done

for go_bin in "${go_bins[@]}"; do
  echo "Building ${go_bin}..."
  cd "${cpwd}/${go_bin}" || exit
  go build "${go_bin}.go"
done

cd "${cpwd}" || exit
server_bins=(
  "${rust_bins[0]}/target/release/${rust_bins[0]}"
)
echo "Running the server..."
"${cpwd}/${server_bins[0]}" &
SERVER_PID=$!
trap 'kill -9 $SERVER_PID' SIGINT SIGTERM

args=(
  "--warmup" "10"
  "--runs" "100"
  "-N"
  "--command-name" "curl"
  "--command-name" "rust-attohttpc"
  "--command-name" "rust-hyper"
  "--command-name" "rust-reqwest"
  "--command-name" "rust-ureq"
  "--command-name" "go-http-client"
  "--command-name" "python-requests"
  "--command-name" "python-urllib3"
)

commands=("curl -H 'Accept-Encoding: gzip' 'http://127.0.0.1:8000/get?range=1-1000'")

for rust_bin in "${rust_bins[@]:1}"; do
  commands+=("${cpwd}/${rust_bin}/target/release/${rust_bin}")
done

for go_bin in "${go_bins[@]}"; do
  commands+=("${cpwd}/${go_bin}/${go_bin}")
done

for python_bin in "${python_bins[@]}"; do
  commands+=("python ${cpwd}/${python_bin}/${python_bin}.py")
done

hyperfine "${args[@]}" "${commands[@]}" -i --export-json benchmarks.json --export-markdown benchmarks.md
sed -i "s|$cpwd\/||g" benchmarks.*

kill -9 "$SERVER_PID"
