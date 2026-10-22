import os
from concurrent.futures import ThreadPoolExecutor

import niquests

URL = "http://127.0.0.1:8000" + os.environ.get("BENCH_PATH", "/ping")
COUNT = int(os.environ.get("BENCH_COUNT", "5000"))
CONCURRENCY = max(1, int(os.environ.get("BENCH_CONCURRENCY", "1")))

session = niquests.Session(
    headers={"connection": "keep-alive"},
    pool_connections=CONCURRENCY,
    pool_maxsize=CONCURRENCY,
)


def fetch(_):
    response = session.get(URL)
    return len(response.content)


with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
    result = sum(executor.map(fetch, range(COUNT)))

print(result)
