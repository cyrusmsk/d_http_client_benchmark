#!/usr/bin/env bash

cpwd="$(pwd)"
required_bins=('cargo' 'go' 'python' 'dub' 'g++' 'swiftc' 'zig' 'Rscript')
rust_bins=('rust-ureq' 'rust-reqwest')
go_bins=('go-http-client')
dotnet_bins=('dotnet-http-client')
cpp_bins=('cpp-http-client')
swift_bins=('swift-urlsession')
zig_bins=('zig-http-client')
python_bins=()
for d in "${cpwd}"/python-*/; do
  [ -d "$d" ] || continue
  bin="$(basename "$d")"
  [ -f "${d}/${bin}.py" ] || continue
  python_bins+=("$bin")
done
r_bins=('r-httr' 'r-httr2')
dlang_bins=('dlang-server' 'dlang-vibed' 'dlang-arsd' 'dlang-requests' 'dlang-ae-http')

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

for cpp_bin in "${cpp_bins[@]}"; do
  echo "Building ${cpp_bin}..."
  cd "${cpwd}/${cpp_bin}" || exit
  g++ -std=c++17 -O2 -pthread "${cpp_bin}.cpp" -o "${cpp_bin}"
done

for swift_bin in "${swift_bins[@]}"; do
  echo "Building ${swift_bin}..."
  cd "${cpwd}/${swift_bin}" || exit
  swiftc -O -parse-as-library "${swift_bin}.swift" -o "${swift_bin}"
done

for zig_bin in "${zig_bins[@]}"; do
  echo "Building ${zig_bin}..."
  cd "${cpwd}/${zig_bin}" || exit
  zig build-exe -O ReleaseFast -lc "${zig_bin}.zig"
done

for dlang_bin in "${dlang_bins[@]}"; do
  echo "Building ${dlang_bin}..."
  cd "${cpwd}/${dlang_bin}" || exit
  dub build -b=release
done

cd "${cpwd}" || exit
echo "Running the server..."
"${cpwd}/dlang-server/dlang-server" &
SERVER_PID=$!
trap 'kill -9 $SERVER_PID; pkill -9 -f dlang-server' SIGINT SIGTERM

RESULTS_FILE="/tmp/bench_results.tsv"
: > "$RESULTS_FILE"

sleep 2

names=()
cmds=()

for go_bin in "${go_bins[@]}"; do
  names+=("$go_bin"); cmds+=("${cpwd}/${go_bin}/${go_bin}")
done
for dotnet_bin in "${dotnet_bins[@]}"; do
  names+=("$dotnet_bin"); cmds+=("${cpwd}/${dotnet_bin}/bin/Release/net8.0/${dotnet_bin}")
done
for python_bin in "${python_bins[@]}"; do
  names+=("$python_bin"); cmds+=("python ${cpwd}/${python_bin}/${python_bin}.py")
done
for r_bin in "${r_bins[@]}"; do
  names+=("$r_bin"); cmds+=("Rscript ${cpwd}/${r_bin}/${r_bin}.r")
done
for rust_bin in "${rust_bins[@]}"; do
  names+=("$rust_bin"); cmds+=("${cpwd}/${rust_bin}/target/release/${rust_bin}")
done
for dlang_bin in "${dlang_bins[@]:1}"; do
  names+=("$dlang_bin"); cmds+=("${cpwd}/${dlang_bin}/${dlang_bin}")
done
for cpp_bin in "${cpp_bins[@]}"; do
  names+=("$cpp_bin"); cmds+=("${cpwd}/${cpp_bin}/${cpp_bin}")
done
for swift_bin in "${swift_bins[@]}"; do
  names+=("$swift_bin"); cmds+=("${cpwd}/${swift_bin}/${swift_bin}")
done
for zig_bin in "${zig_bins[@]}"; do
  names+=("$zig_bin"); cmds+=("${cpwd}/${zig_bin}/${zig_bin}")
done

BENCH_SCALE=${BENCH_SCALE:-1}
FIRST_BYTE_WARMUP=true

run_test() {
  local test="$1"
  local path="$2"
  local count="$3"
  local concurrency="$4"

  count=$((count * BENCH_SCALE))
  if [ "$count" -lt 1 ]; then
    count=1
  fi

  for i in "${!names[@]}"; do
    name="${names[$i]}"
    cmd="${cmds[$i]}"
    python3 - "$test" "$name" "$cmd" "$RESULTS_FILE" "$path" "$count" "$concurrency" <<'PY'
import os
import subprocess
import sys
import time

test, name, cmd, results_file, path, count, concurrency = sys.argv[1:8]

env = os.environ.copy()
env["BENCH_PATH"] = path
env["BENCH_COUNT"] = count
env["BENCH_CONCURRENCY"] = concurrency

start = time.perf_counter()
try:
    proc = subprocess.run(
        cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=env,
        timeout=180,
    )
    output = proc.stdout.replace("\r", " ").replace("\n", " ").strip()
except subprocess.TimeoutExpired:
    output = "TIMEOUT"
elapsed = time.perf_counter() - start
if "\t" in output:
    output = output.replace("\t", " ")

print(f"{test} {name}: {output} (elapsed: {elapsed:.3f}s)")
with open(results_file, "a") as f:
    f.write(f"{test}\t{name}\t{output}\t{elapsed:.6f}\n")
PY
  done
}

# Test A — warm keep-alive requests
run_test "A-warm-1" "/ping" 5000 1
run_test "A-warm-10" "/ping" 5000 10
run_test "A-warm-100" "/ping" 5000 100
run_test "A-warm-500" "/ping" 2000 500

# Test C — response body processing
run_test "C-body-64k" "/download" 1000 100
run_test "C-json-1k" "/json" 1000 100
run_test "C-large-1m" "/large?size=1048576" 100 100

# Test D — latency/concurrency under server-side delay
run_test "D-delay-10ms" "/delay?ms=10" 200 10

# Status handling
run_test "error-status-404" "/status/404" 200 1

python3 - "$RESULTS_FILE" <<'PY'
import json, sys
rows = []
with open(sys.argv[1]) as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 4:
            continue
        test, name, output, secs = parts[0], parts[1], parts[2], parts[3]
        try:
            value = float(secs)
        except ValueError:
            value = 0.0
        rows.append({"test": test, "command": name, "times": [value], "stdout": output})
with open("benchmarks.json", "w") as f:
    json.dump({"results": rows}, f, indent=2)


def split(results, predicate, filename):
    selected = [row for row in results if predicate(row["command"])]
    with open(filename, "w") as f:
        json.dump({"results": selected}, f, indent=2)


split(rows, lambda command: command.startswith("python-"), "benchmarks-python.json")
split(rows, lambda command: command.startswith("r-"), "benchmarks-r.json")
split(
    rows,
    lambda command: not command.startswith("python-") and not command.startswith("r-"),
    "benchmarks-rest.json",
)
PY

kill -9 "$SERVER_PID" 2>/dev/null || true
pkill -9 -f dlang-server 2>/dev/null || true

exit 0