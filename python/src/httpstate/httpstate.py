# HTTP State, https://httpstate.com/
# Copyright (C) Alex Morales, 2026

# Unless otherwise stated in particular files or directories, this software is free software.
# You can redistribute it and/or modify it under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.

import asyncio
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

def read(uuid:str) -> None|str:
  return get(uuid)

def set(uuid:str, data:str) -> None|int:
  req = urllib.request.Request(
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

def write(uuid:str, data:str) -> None|int:
  return set(uuid, data)

# HTTP State
class HttpState:
  def __init__(self, uuid:str):
    self.data:None|str = None
    self.el:None|asyncio.AbstractEventLoop = None
    self.et:Dict[str, List[Callable[[None|str], None]]] = {}
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
  
  def _el(self):
    self.el = asyncio.new_event_loop()
    
    asyncio.set_event_loop(self.el)
    
    self.el.call_soon_threadsafe(lambda : self.get())

    self.el.run_forever()

  async def _ws(self):
    self.ws = await websockets.connect(f"wss://httpstate.com/{self.uuid}")

    await self.ws.send(f'{{"open":"{self.uuid}"}}')
    self.emit('open')

    async def data():
      async for data in self.ws:
        data = data.decode()

        if(
              data
          and len(data) > 32
          and data[:32] == self.uuid
          and data[45] == '1'
        ):
          self.data = data[46:]

          self.emit('change', self.data)
    
    asyncio.create_task(data())

    async def interval():
      while True:
        try:
          await self.ws.ping()

          await asyncio.sleep(30) # 30 SECONDS
        except websockets.ConnectionClosed:
          break

    asyncio.create_task(interval())
    
    await asyncio.Event().wait()
  
  def destroy(self):
    pass

  def emit(self, type:str, data:None|str = None):
    for callback in self.et.get(type, []):
      if(data is None):
        callback()
      else:
        callback(data)

    return self

  def get(self) -> None|str:
    data = get(self.uuid)

    if(data != self.data):
      self.el.call_soon_threadsafe(lambda : self.emit('change', self.data))

    self.data = data

    return self.data

  def off(self, type:str, callback:Callable[[None|str], None]):
    if type in self.et:
      try:
        self.et[type].remove(callback)
      except ValueError:
        pass

      if not self.et[type]:
        del self.et[type]

    return self

  def on(self, type:str, callback:Callable[[None|str], None]):
    if type not in self.et:
      self.et[type] = []

    self.et[type].append(callback)

    return self

  def read(self) -> None|str:
    return self.get()

  def set(self, data:str) -> None|int:
    return set(self.uuid, data)

  def write(self, data:str) -> None|int:
    return self.set(data)
