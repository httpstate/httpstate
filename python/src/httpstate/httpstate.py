# HTTPState, https://httpstate.com/
# Copyright (C) Alex Morales, 2026

# Unless otherwise stated in particular files or directories, this software is free software.
# You can redistribute it and/or modify it under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.

import asyncio
import datetime
import json
import struct
import threading
import urllib.error
import urllib.request
import websockets

from typing import Callable, Dict, List

def get(uuid:str, args:None|Dict = None) -> None|str|dict:
  try:
    req:urllib.request.Request = urllib.request.Request(f'https://httpstate.com/{uuid}')

    if args and args.get('Authorization'):
      req.add_header('Authorization', args.get('Authorization'))

    with urllib.request.urlopen(req) as f:
      if f.status == 200:
        data:str = f.read().decode('utf-8', 'replace')

        if(
             not args
          or (
                not args.get('ETag')
            and not args.get('Last-Modified')
          )
        ):
          return data
        else:
          return {
            **({ 'ETag':f.headers.get('ETag') } if args.get('ETag') else {}),
            **({ 'Last-Modified':f.headers.get('Last-Modified') } if args.get('Last-Modified') else {}),
            'data':data
          }
  except urllib.error.HTTPError as e:
    if e.code == 401:
      raise Exception('401 Unauthorized')
    elif e.code == 404:
      raise Exception('404 Not Found')
    elif e.code == 429:
      raise Exception('429 Too Many Requests')
  except Exception as e:
    print(datetime.datetime.now().isoformat(), 'get.error', e)
    
    raise e

class MessageType:
  def __init__(self, uuid:str, timestamp:int, type:int, value:bytes) -> None:
    self.uuid:str = uuid
    self.timestamp:int = timestamp
    self.type:int = type
    self.value:bytes = value

class Message:
  @staticmethod
  def unpack(b:bytes) -> None|MessageType:
    header:int = b[0]

    if header == 0:
      length:int = b[1]

      return MessageType(
        uuid=b[2:2+length].decode('utf-8'),
        timestamp=struct.unpack_from('>Q', b, 2+length)[0],
        type=b[2+length+8],
        value=b[2+length+9:]
      )

message:type = Message

def post(uuid:str, data:None|str = None, args:None|Dict = None) -> None|int:
  return set(uuid, data, args)

def put(uuid:str, data:None|str = None, args:None|Dict = None) -> None|int:
  return set(uuid, data, args)

def read(uuid:str, args:None|Dict = None) -> None|str|dict:
  return get(uuid, args)

def set(uuid:str, data:None|str = None, args:None|Dict = None) -> None|int:
  if(data is None):
    data = ''

  headers:Dict[str, str] = { 'Content-Type':'text/plain;charset=UTF-8' }

  if args and args.get('Authorization'):
    headers['Authorization'] = args.get('Authorization')

  req:urllib.request.Request = urllib.request.Request(
    f'https://httpstate.com/{uuid}',
    data=data.encode('utf-8'),
    headers=headers,
    method='POST'
  )

  try:
    with urllib.request.urlopen(req) as f:
      return f.status
  except urllib.error.HTTPError as e:
    if e.code == 401:
      raise Exception('401 Unauthorized')
    elif e.code == 404:
      raise Exception('404 Not Found')
    elif e.code == 413:
      raise Exception('413 Content Too Large')

    return e.code
  except Exception as e:
    print(datetime.datetime.now().isoformat(), 'set.error', e)

def write(uuid:str, data:None|str = None, args:None|Dict = None) -> None|int:
  return set(uuid, data, args)

# HTTPState
class HttpState:
  def __init__(self, uuid:str, args:None|Dict = None) -> None:
    self.authorization:None|str = args.get('Authorization') if args else None
    self.data:None|str = None
    self.el:None|asyncio.AbstractEventLoop = None
    self.et:None|Dict[str, List[Callable[[None|str], None]]] = {}
    self.lock:None|threading.Lock = threading.Lock()
    self.uuid:None|str = uuid
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

    await self.ws.send(json.dumps({ 'open':self.uuid, **({ 'Authorization':self.authorization } if self.authorization is not None else {}) }))

    self.emit('open')

    async def data() -> None:
      async for data in self.ws:
        data:None|MessageType = message.unpack(data)

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
    if self.el is not None:
      if self.ws is not None:
        asyncio.run_coroutine_threadsafe(self.ws.close(), self.el)

      self.el.call_soon_threadsafe(self.el.stop)

    self.authorization = None
    self.data = None
    self.el = None
    self.et = None
    self.lock = None
    self.uuid = None
    self.ws = None

  def emit(self, type:str, data:None|str = None) -> "HttpState":
    if self.et is not None:
      for callback in self.et.get(type, []):
        if(data is None):
          callback()
        else:
          callback(data)

    return self

  def get(self) -> None|str:
    args:None|Dict = { 'Authorization':self.authorization } if self.authorization is not None else None
    data:None|str = get(self.uuid, args)

    with self.lock:
      if(data != self.data):
        if self.el is not None:
          self.el.call_soon_threadsafe(lambda : self.emit('change', self.data))

      self.data = data

    return self.data

  def off(self, type:str, callback:Callable[[None|str], None]) -> "HttpState":
    if self.et is not None and type in self.et:
      try:
        self.et[type].remove(callback)
      except ValueError:
        pass

      if not self.et[type]:
        del self.et[type]

    return self

  def on(self, type:str, callback:Callable[[None|str], None]) -> "HttpState":
    if self.et is not None:
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
    args:None|Dict = { 'Authorization':self.authorization } if self.authorization is not None else None
    return set(self.uuid, data, args)

  def write(self, data:None|str = None) -> None|int:
    return self.set(data)
