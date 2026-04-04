use chrono::Utc;

#[tokio::main]
async fn main() {
  httpstate::HttpState::new("58bff2fcbeb846958f36e7ae5b8a75b0")
    .on("change", |data| {
      println!("{:?} data {:?}", Utc::now().to_rfc3339(), data.unwrap())
    });

  // Not needed per se, only meant to keep the script alive
  tokio::signal::ctrl_c().await.unwrap();
}
