#!/usr/bin/env bash

cpwd="$(pwd)"
required_bins=('cargo' 'go' 'python' 'dub' 'hyperfine')
rust_bins=('rust-ureq' 'rust-reqwest')
go_bins=('go-http-client')
dotnet_bins=('dotnet-http-client')
python_bins=('python-requests' 'python-httpx')
r_bins=('r-httr' 'r-httr2')
dlang_bins=('dlang-server' 'dlang-arsd' 'dlang-vibed' 'dlang-requests')

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

for dotnet_bin in "${dotnet_bins[@]}"; do
  echo "Building ${dotnet_bin}..."
  cd "${cpwd}/${dotnet_bin}" || exit
  dotnet build --configuration Release
done

for dlang_bin in "${dlang_bins[@]}"; do
  echo "Building ${dlang_bin}..."
  dub build -b=release --root="${cpwd}/${dlang_bin}"
done

cd "${cpwd}" || exit
server_bins=(
  "${dlang_bins[0]}/${dlang_bins[0]}"
)
echo "Running the server..."
"${cpwd}/${server_bins[0]}" &
SERVER_PID=$!
trap 'kill -9 $SERVER_PID' SIGINT SIGTERM

args=(
  "--warmup" "5"
  "--runs" "50"
  "-N"
  "--command-name" "go-http-client"
  "--command-name" "dotnet-http-client"
  "--command-name" "python-requests"
  "--command-name" "python-httpx"
  "--command-name" "r-httr"
  "--command-name" "r-httr2"
  "--command-name" "rust-ureq"
  "--command-name" "rust-reqwest"
  "--command-name" "dlang-arsd"
  "--command-name" "dlang-vibed"
  "--command-name" "dlang-requests"
)

sleep 2

for go_bin in "${go_bins[@]}"; do
  commands=("${cpwd}/${go_bin}/${go_bin}")
done

for dotnet_bin in "${dotnet_bins[@]}"; do
  commands+=("${cpwd}/${dotnet_bin}/bin/Release/net8.0/${dotnet_bin}")
done

for python_bin in "${python_bins[@]}"; do
  commands+=("python ${cpwd}/${python_bin}/${python_bin}.py")
done

for r_bin in "${r_bins[@]}"; do
  commands+=("Rscript ${cpwd}/${r_bin}/${r_bin}.r")
done

for rust_bin in "${rust_bins[@]}"; do
  commands+=("${cpwd}/${rust_bin}/target/release/${rust_bin}")
done

for dlang_bin in "${dlang_bins[@]:1}"; do
  commands+=("${cpwd}/${dlang_bin}/${dlang_bin}")
done

hyperfine "${args[@]}" "${commands[@]}" -i --export-json benchmarks.json --export-markdown benchmarks.md
sed -i "s|${cpwd}\/||g" benchmarks.*

kill -9 "$SERVER_PID"
