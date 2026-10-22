use std::thread;

fn env_usize(name: &str, fallback: usize) -> usize {
    std::env::var(name)
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .filter(|v| *v > 0)
        .unwrap_or(fallback)
}

fn main() {
    let path = std::env::var("BENCH_PATH").unwrap_or_else(|_| "/ping".to_string());
    let total = env_usize("BENCH_COUNT", 5000);
    let concurrency = env_usize("BENCH_CONCURRENCY", 1);
    let url = format!("http://127.0.0.1:8000{path}");

    let mut handles = Vec::new();
    for worker in 0..concurrency.min(total) {
        let url = url.clone();
        handles.push(thread::spawn(move || {
            let client = ureq::builder().no_delay(true).build();
            let mut result = 0usize;

            let mut index = worker;
            while index < total {
                match client.get(&url).set("connection", "keep-alive").call() {
                    Ok(response) => {
                        result += response.into_string().map(|body| body.len()).unwrap_or(0)
                    }
                    Err(_) => result += 0,
                }
                index += concurrency.min(total);
            }
            result
        }));
    }

    let result: usize = handles.into_iter().map(|h| h.join().unwrap()).sum();
    println!("{result}");
}