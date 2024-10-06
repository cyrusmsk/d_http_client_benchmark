fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = ureq::builder().no_delay(true).build();
    let mut result = 0;

    for i in 1..=5000 {
        let response = client
            .get("http://127.0.0.1:8000/get")
            .set("connection", "keep-alive")
            .call()?
            .into_string()?;
        result += response.parse::<i32>().unwrap();
    }

    println!("{result}");
    Ok(())
}
