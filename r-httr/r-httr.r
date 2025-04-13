#!/usr/bin/env Rscript

library(httr)
url <- "http://127.0.0.1:8000/get"

result <- 0
for (i in 0:4999) {
    response <- GET(
        url = "http://127.0.0.1:8000/get",
        add_headers(
            "Connection" = "keep-alive"
        )
    )
    result = result + as.numeric(content(response, "text"))
}
print(result)
