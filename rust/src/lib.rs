// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

pub async fn get(uuid:&str) -> Option<String> {
  let url = format!("https://httpstate.com/{}", uuid);

  match reqwest::get(&url).await {
    Err(_) => None,
    Ok(response) => {
      if response.status() == reqwest::StatusCode::OK {
        match response.bytes().await {
          Err(_) => None,
          Ok(b) => Some(String::from_utf8_lossy(&b).into_owned())
        }
      } else {
        None
      }
    }
  }
}

pub async fn read(uuid:&str) -> Option<String> {
  get(uuid).await
}

pub async fn set(uuid:&str, data:&str) -> Option<u16> {
  let url = format!("https://httpstate.com/{}", uuid);

  let response = reqwest::Client::new()
    .post(&url)
    .header(reqwest::header::CONTENT_TYPE, "text/plain;charset=UTF-8")
    .body(data.to_string())
    .send()
    .await
    .ok()?;

  Some(response.status().as_u16())
}

pub async fn write(uuid:&str, data:&str) -> Option<u16> {
  set(uuid, data).await
}

// HTTP State
pub struct HttpState {
  pub data:Option<String>,
  pub et:std::collections::HashMap<String, Vec<Box<dyn Fn(Option<String>)>>>,
  pub uuid:String
}

imp HttpState {
  fn new(uuid:&str) -> Self {
    // ...
  }
}
