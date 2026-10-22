import os
from concurrent.futures import ThreadPoolExecutor

import httpx

URL = "http://127.0.0.1:8000" + os.environ.get("BENCH_PATH", "/ping")
COUNT = int(os.environ.get("BENCH_COUNT", "5000"))
CONCURRENCY = int(os.environ.get("BENCH_CONCURRENCY", "1"))
CONCURRENCY = max(1, CONCURRENCY)

limits = httpx.Limits(
    max_connections=CONCURRENCY,
    max_keepalive_connections=CONCURRENCY,
)

with httpx.Client(limits=limits, headers={"connection": "keep-alive"}) as client:
    def fetch(_):
        response = client.get(URL)
        return len(response.content)

    with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        result = sum(executor.map(fetch, range(COUNT)))

print(result)
