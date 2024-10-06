use std::time::Duration;

use reqwest::Client;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()?
        .block_on(async {
            let mut result = 0;
            let client = Client::builder()
                .tcp_nodelay(true)
                .tcp_keepalive(Some(Duration::from_secs(30)))
                .build()?;

            for i in 1..=5000 {
                let response = client
                    .get("http://127.0.0.1:8000/get")
                    .header("connection", "keep-alive")
                    .send()
                    .await?
                    .text()
                    .await?;
                result += response.parse::<i32>()?;
            }

            println!("{result}");
            Ok(())
        })
}
