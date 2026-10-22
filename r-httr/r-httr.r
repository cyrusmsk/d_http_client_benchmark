#!/usr/bin/env Rscript
library(httr)

path <- Sys.getenv("BENCH_PATH", "/ping")
count <- as.integer(Sys.getenv("BENCH_COUNT", "5000"))

url <- paste0("http://127.0.0.1:8000", path)
result <- 0

for (i in seq_len(count)) {
    response <- GET(
        url = url,
        add_headers(Connection = "keep-alive")
    )
    body <- content(response, as = "raw", encoding = "UTF-8")
    body_length <- if (is.null(body)) 0L else length(body)
    result <- result + body_length
}

print(result)
