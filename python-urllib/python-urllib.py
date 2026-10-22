import os
from concurrent.futures import ThreadPoolExecutor

import urllib3

PATH = os.environ.get("BENCH_PATH", "/ping")
COUNT = int(os.environ.get("BENCH_COUNT", "5000"))
CONCURRENCY = max(1, int(os.environ.get("BENCH_CONCURRENCY", "1")))

conn = urllib3.connection_from_url(
    "http://127.0.0.1:8000", maxsize=CONCURRENCY
)


def fetch(_):
    response = conn.request("GET", PATH, headers={"connection": "keep-alive"})
    return len(response.data)


with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
    result = sum(executor.map(fetch, range(COUNT)))

print(result)
