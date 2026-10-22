import os
from concurrent.futures import ThreadPoolExecutor

import requests
from requests.adapters import HTTPAdapter

URL = "http://127.0.0.1:8000" + os.environ.get("BENCH_PATH", "/ping")
COUNT = int(os.environ.get("BENCH_COUNT", "5000"))
CONCURRENCY = max(1, int(os.environ.get("BENCH_CONCURRENCY", "1")))

session = requests.Session()
session.mount(
    "http://",
    HTTPAdapter(pool_connections=CONCURRENCY, pool_maxsize=CONCURRENCY),
)


def fetch(_):
    response = session.get(URL, headers={"connection": "keep-alive"})
    return len(response.content)


with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
    result = sum(executor.map(fetch, range(COUNT)))

print(result)
