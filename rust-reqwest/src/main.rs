use std::sync::Arc;
use std::time::Duration;

use reqwest::Client;
use tokio::runtime;
use tokio::sync::Semaphore;
use tokio::task::JoinSet;

fn env_usize(name: &str, fallback: usize) -> usize {
    std::env::var(name)
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .filter(|v| *v > 0)
        .unwrap_or(fallback)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .enable_all()
        .build()?
        .block_on(async {
            let path = std::env::var("BENCH_PATH").unwrap_or_else(|_| "/ping".to_string());
            let count = env_usize("BENCH_COUNT", 5000);
            let concurrency = env_usize("BENCH_CONCURRENCY", 1);
            let url = format!("http://127.0.0.1:8000{path}");

            let client = Client::builder()
                .tcp_nodelay(true)
                .tcp_keepalive(Some(Duration::from_secs(30)))
                .pool_max_idle_per_host(concurrency)
                .build()?;

            let sem = Arc::new(Semaphore::new(concurrency));
            let mut set = JoinSet::new();
            let mut result = 0usize;

            for _ in 0..count {
                let client = client.clone();
                let sem = sem.clone();
                let url = url.clone();
                set.spawn(async move {
                    let _permit = sem.acquire().await.unwrap();
                    let mut last_error = None;
                    for attempt in 0..8 {
                        let response = client
                            .get(url.clone())
                            .header("connection", "keep-alive")
                            .send()
                            .await;

                        match response {
                            Ok(response) => {
                                let body = response.bytes().await?;
                                return Ok::<usize, reqwest::Error>(body.len());
                            }
                            Err(error) => {
                                last_error = Some(error);
                                tokio::time::sleep(std::time::Duration::from_millis(
                                    25 * (attempt + 1) as u64,
                                ))
                                .await;
                            }
                        }
                    }
                    Err(last_error.expect("at least one request error"))
                });
            }

            while let Some(joined) = set.join_next().await {
                result += joined??;
            }

            println!("{result}");
            Ok(())
        })
}