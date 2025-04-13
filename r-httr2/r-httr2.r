#!/usr/bin/env Rscript
library(httr2)

url_base <- "http://127.0.0.1:8000/get"
req_base <- request(url_base) |> req_headers(Connection = "keep-alive")
reqs <- rep(list(req_base), 5000)
resps <- req_perform_parallel(reqs, progress=FALSE)
res <- sum(as.numeric(lapply(resps, resp_body_string)))
print(res)
