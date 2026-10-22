#!/usr/bin/env Rscript
library(httr2)

path <- Sys.getenv("BENCH_PATH", "/ping")
count <- as.integer(Sys.getenv("BENCH_COUNT", "5000"))
max_active <- as.integer(Sys.getenv("BENCH_CONCURRENCY", "10"))

url_base <- paste0("http://127.0.0.1:8000", path)
req_base <- request(url_base) |> req_headers(Connection = "keep-alive")
reqs <- rep(list(req_base), count)
resps <- req_perform_parallel(reqs, max_active = max_active, on_error = "return", progress = FALSE)
body_length <- function(resp) {
  if (is.null(resp) || !inherits(resp, "httr2_response")) {
    return(0L)
  }
  nchar(resp_body_string(resp), type = "bytes")
}

res <- sum(unlist(lapply(resps, body_length)))
print(res)
