# HTTPState, https://httpstate.com/
# Copyright (C) Alex Morales, 2026

# Unless otherwise stated in particular files or directories, this software is free software.
# You can redistribute it and/or modify it under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.

import asyncio
import struct
import threading
import urllib.error
import urllib.request
import websockets

from typing import Callable, Dict, List

def get(uuid:str) -> None|str:
  try:
    with urllib.request.urlopen(f'https://httpstate.com/{uuid}') as f:
      if f.status == 200:
        return f.read().decode('utf-8', 'replace')

      return None
  except urllib.error.HTTPError:
    return None
  except Exception:
    return None

class MessageType:
  def __init__(self, uuid:str, timestamp:int, type:int, value:bytes) -> None:
    self.uuid:str = uuid
    self.timestamp:int = timestamp
    self.type:int = type
    self.value:bytes = value

class Message:
  @staticmethod
  def unpack(b:bytes) -> MessageType:
    length:int = b[0]

    return MessageType(
      uuid=b[1:1+length].decode('utf-8'),
      timestamp=struct.unpack_from('>Q', b, 1+length)[0],
      type=b[1+length+8],
      value=b[1+length+9:],
    )

message:type = Message

def post(uuid:str, data:None|str = None) -> None|int:
  return set(uuid, data)

def put(uuid:str, data:None|str = None) -> None|int:
  return set(uuid, data)

def read(uuid:str) -> None|str:
  return get(uuid)

def set(uuid:str, data:None|str = None) -> None|int:
  if(data is None):
    data = ''

  req:urllib.request.Request = urllib.request.Request(
    f'https://httpstate.com/{uuid}',
    data=data.encode('utf-8'),
    headers={ 'Content-Type':'text/plain;charset=UTF-8' },
    method='POST'
  )

  try:
    with urllib.request.urlopen(req) as f:
      return f.status
  except urllib.error.HTTPError as e:
    return e.code
  except Exception:
    return None

def write(uuid:str, data:None|str = None) -> None|int:
  return set(uuid, data)

# HTTPState
class HttpState:
  def __init__(self, uuid:str) -> None:
    self.data:None|str = None
    self.el:None|asyncio.AbstractEventLoop = None
    self.et:Dict[str, List[Callable[[None|str], None]]] = {}
    self.lock:threading.Lock = threading.Lock()
    self.uuid:str = uuid
    self.ws:None|websockets.WebSocketClientProtocol = None

    threading.Thread(
      daemon=True,
      target=self._el
    ).start()

    threading.Thread(
      daemon=True,
      target=lambda : asyncio.run(self._ws())
    ).start()
  
  def _el(self) -> None:
    self.el:asyncio.AbstractEventLoop = asyncio.new_event_loop()
    
    asyncio.set_event_loop(self.el)
    
    self.el.call_soon_threadsafe(lambda : self.get())

    self.el.run_forever()

  async def _ws(self) -> None:
    self.ws:websockets.WebSocketClientProtocol = await websockets.connect(f"wss://httpstate.com/{self.uuid}")

    await self.ws.send(f'{{"open":"{self.uuid}"}}')
    self.emit('open')

    async def data() -> None:
      async for data in self.ws:
        data:MessageType = message.unpack(data)

        if(
              data
          and data.uuid == self.uuid
          and data.type == 1
        ):
          with self.lock:
            self.data:None|str = data.value.decode()

          self.emit('change', self.data)
    
    asyncio.create_task(data())

    async def interval() -> None:
      while True:
        try:
          await self.ws.ping()

          await asyncio.sleep(30) # 30 SECONDS
        except websockets.ConnectionClosed:
          break

    asyncio.create_task(interval())
    
    await asyncio.Event().wait()
  
  def delete(self) -> None:
    pass

  def emit(self, type:str, data:None|str = None) -> "HttpState":
    for callback in self.et.get(type, []):
      if(data is None):
        callback()
      else:
        callback(data)

    return self

  def get(self) -> None|str:
    data:None|str = get(self.uuid)

    with self.lock:
      if(data != self.data):
        if self.el is not None:
          self.el.call_soon_threadsafe(lambda : self.emit('change', self.data))

      self.data = data

    return self.data

  def off(self, type:str, callback:Callable[[None|str], None]) -> "HttpState":
    if type in self.et:
      try:
        self.et[type].remove(callback)
      except ValueError:
        pass

      if not self.et[type]:
        del self.et[type]

    return self

  def on(self, type:str, callback:Callable[[None|str], None]) -> "HttpState":
    if type not in self.et:
      self.et[type] = []

    self.et[type].append(callback)

    return self
  
  def post(self, data:None|str = None) -> None|int:
    return self.set(data)
  
  def put(self, data:None|str = None) -> None|int:
    return self.set(data)

  def read(self) -> None|str:
    return self.get()

  def set(self, data:None|str = None) -> None|int:
    return set(self.uuid, data)

  def write(self, data:None|str = None) -> None|int:
    return self.set(data)
