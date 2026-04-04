// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

use std::collections::HashMap;
use std::net::TcpStream;
use std::sync::{Arc, Mutex};
use tungstenite::protocol::WebSocket;
use tungstenite::stream::MaybeTlsStream;

pub async fn get(uuid:&str) -> Option<String> {
  let url = format!("https://httpstate.com/{}", uuid);

  match reqwest::get(&url).await {
    Err(_) => None,
    Ok(response) => {
      if response.status() == reqwest::StatusCode::OK {
        match response.bytes().await {
          Err(_) => None,
          Ok(bytes) => Some(String::from_utf8_lossy(&bytes).into_owned())
        }
      } else {
        None
      }
    }
  }
}

pub mod message {
  use crate::HttpStateMessageType;
  
  pub fn unpack(b:&[u8]) -> HttpStateMessageType {
    let length:usize = b[0] as usize;

    HttpStateMessageType {
      uuid:String::from_utf8(b[1..1+length].to_vec()).unwrap(),
      timestamp:u64::from_be_bytes(b[1+length..1+length+8].try_into().unwrap()),
      r#type:b[1+length+8],
      value:b[1+length+9..].to_vec()
    }
  }
}

pub async fn post(uuid:&str, data:&str) -> Option<u16> {
  set(uuid, data).await
}

pub async fn put(uuid:&str, data:&str) -> Option<u16> {
  set(uuid, data).await
}

pub async fn read(uuid:&str) -> Option<String> {
  get(uuid).await
}

pub async fn set(uuid:&str, data:&str) -> Option<u16> {
  let url = format!("https://httpstate.com/{}", uuid);

  let response = reqwest::Client::new()
    .post(&url)
    .header(reqwest::header::CONTENT_TYPE, "text/plain;charset=UTF-8")
    .body(String::from(data))
    .send()
    .await
    .ok()?;

  Some(response.status().into())
}

pub async fn write(uuid:&str, data:&str) -> Option<u16> {
  set(uuid, data).await
}

// HTTP State
pub struct HttpState {
  pub data:Arc<Mutex<Option<String>>>,
  pub et:Arc<Mutex<HashMap<String, Vec<Box<dyn Fn(Option<String>) + Send + Sync>>>>>,
  pub uuid:String,
  pub ws:Arc<Mutex<Option<WebSocket<MaybeTlsStream<TcpStream>>>>>
}

pub struct HttpStateMessageType {
  pub uuid:String,
  pub timestamp:u64,
  pub r#type:u8,
  pub value:Vec<u8>
}

impl HttpState {
  pub fn new(uuid:&str) -> Arc<Self> {
    let httpstate = Arc::new(HttpState {
      data:Arc::new(Mutex::new(None)),
      et:Arc::new(Mutex::new(HashMap::new())),
      uuid:String::from(uuid),
      ws:Arc::new(Mutex::new(None))
    });

    let httpstate_clone = Arc::clone(&httpstate);
    
    std::thread::spawn(move || {
      match tungstenite::connect(&format!("wss://httpstate.com/{}", httpstate_clone.uuid)) {
        Err(_) => {},
        Ok((mut ws, _)) => {
          let stream = ws.get_mut();

          match stream {
            tungstenite::stream::MaybeTlsStream::NativeTls(nativetls) => {
              let _ = nativetls.get_mut().set_read_timeout(Some(std::time::Duration::from_secs(10))); // 10 SECONDS
            },
            _ => {}
          }

          {
            let mut lock = httpstate_clone.ws.lock().unwrap();

            *lock = Some(ws);
          }
          
          {
            let mut lock = httpstate_clone.ws.lock().unwrap();

            let _ = lock.as_mut().unwrap()
              .send(tungstenite::Message::Text(format!("{{\"open\":\"{}\"}}", httpstate_clone.uuid).into()));
          }

          let httpstate_clone_interval = Arc::clone(&httpstate_clone);

          std::thread::spawn(move || {
            loop {
              // eprintln!("[DEBUG] interval");

              {
                let mut lock = httpstate_clone_interval.ws.lock().unwrap();

                let _ = lock.as_mut().unwrap()
                  .send(tungstenite::Message::Ping(vec![].into()));
              }

              std::thread::sleep(std::time::Duration::from_secs(30)); // 30 SECONDS
            }
          });

          let httpstate_clone_read = Arc::clone(&httpstate_clone);
          std::thread::spawn(move || {
            loop {
              // eprintln!("[DEBUG] loop");

              let _data = {
                let mut lock = httpstate_clone_read.ws.lock().unwrap();

                lock.as_mut().unwrap().read()
              };

              match _data {
                Err(e) => {
                  match e {
                    tungstenite::Error::Io(ref io_err) if io_err.kind() == std::io::ErrorKind::WouldBlock => {},
                    _ => {
                      eprintln!("[DEBUG] loop.e {:?}", e);

                      break;
                    }
                  }
                },
                Ok(_data) => {
                  match _data {
                    tungstenite::Message::Binary(bytes) => {
                      let data:HttpStateMessageType = message::unpack(&bytes);

                      if data.uuid == httpstate_clone_read.uuid
                        && data.r#type == 1
                      {
                        let mut lock = httpstate_clone_read.data.lock().unwrap();
                        
                        *lock = Some(String::from_utf8_lossy(&data.value).to_string());

                        httpstate_clone_read.emit("change", lock.clone());
                      }
                    },
                    _ => {}
                  }
                }
              }
            }
          });
        }
      }
    });

    httpstate
  }

  pub fn emit(&self, _type:&str, _data:Option<String>) {
    let lock = self.et.lock().unwrap();

    if let Some(vec) = lock.get(_type) {
      for callback in vec.iter() {
        callback(_data.clone());
      }
    }
  }

  pub async fn get(&self) -> Option<String> {
    get(&self.uuid).await
  }

  pub fn off<F>(&self, _type:&str, _callback:F)
  where F:Fn(Option<String>) + Send + Sync + 'static, {
    // ...
  }

  pub fn on<F>(&self, _type:&str, _callback:F)
  where F:Fn(Option<String>) + Send + Sync + 'static, {
    let mut lock = self.et.lock().unwrap();

    lock
      .entry(String::from(_type))
      .or_insert_with(Vec::new)
      .push(Box::new(_callback));
  }

  pub async fn post(&self, data:&str) -> Option<u16> {
    set(&self.uuid, data).await
  }

  pub async fn put(&self, data:&str) -> Option<u16> {
    set(&self.uuid, data).await
  }

  pub async fn read(&self) -> Option<String> {
    get(&self.uuid).await
  }

  pub async fn set(&self, data:&str) -> Option<u16> {
    set(&self.uuid, data).await
  }

  pub async fn write(&self, data:&str) -> Option<u16> {
    set(&self.uuid, data).await
  }
}
