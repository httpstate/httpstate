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

          eprintln!("stream {:?}", stream);

          match stream {
            tungstenite::stream::MaybeTlsStream::NativeTls(nativetls) => {
              eprintln!("nativetls {:?}", nativetls);

              let ss = nativetls.get_mut();

              eprintln!("ss {:?}", ss);

              let _ = ss.set_read_timeout(Some(std::time::Duration::from_secs(10))); // 10 SECONDS
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
              eprintln!("[DEBUG] interval");

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
              eprintln!("[DEBUG] read");

              let message = {
                let mut lock = httpstate_clone_read.ws.lock().unwrap();

                lock.as_mut().unwrap().read()
              };

              match message {
                Err(e) => {
                  match e {
                    tungstenite::Error::Io(ref io_err) if io_err.kind() == std::io::ErrorKind::WouldBlock => {},
                    _ => {
                      eprintln!("[DEBUG] loop.e {:?}", e);

                      break;
                    }
                  }
                },
                Ok(message) => {
                  match message {
                    tungstenite::Message::Binary(bytes) => {
                      match String::from_utf8(bytes.to_vec()) {
                        Err(_) => {},
                        Ok(data) => {
                          {
                            let mut lock = httpstate_clone_read.data.lock().unwrap();
                            
                            *lock = Some(data.clone());
                          }

                          {
                            let lock = httpstate_clone_read.data.lock().unwrap();

                            let data = lock.as_ref().unwrap();
                            
                            if   !data.is_empty()
                              && data.len() > 46
                              && &data[..32] == httpstate_clone_read.uuid
                              && data.as_bytes()[45] == b'1'
                            {
                              httpstate_clone_read.emit("change", Some(String::from(&data[46..])));
                            }
                          }
                        }
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

  pub async fn read(&self) -> Option<String> {
    read(&self.uuid).await
  }

  pub async fn set(&self, data:&str) -> Option<u16> {
    set(&self.uuid, data).await
  }

  pub async fn write(&self, data:&str) -> Option<u16> {
    write(&self.uuid, data).await
  }
}
