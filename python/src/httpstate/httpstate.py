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
  except urllib.error.HTTPError:
    return None

def write(uuid:str, data:str) -> None|int:
  return set(uuid, data)

# HTTP State
class HttpState:
  def __init__(self, uuid:str):
    self.data:None|str = None
    self.et:Dict[str, List[Callable[[None|str], None]]] = {}
    self.uuid:str = uuid
    self.ws:None|websockets.WebSocketClientProtocol = None

    threading.Thread(
      daemon=True,
      target=lambda : asyncio.run(self._ws())
    ).start()

  async def _ws(self):
    self.ws = await websockets.connect(f"wss://httpstate.com/{self.uuid}")

    await self.ws.send(f'{{"open":"{self.uuid}"}}')

    async def interval():
      while True:
        try:
          await self.ws.ping()

          await asyncio.sleep(30) # 30 SECONDS
        except websockets.ConnectionClosed:
          break

    asyncio.create_task(interval())

    async for data in self.ws:
      self.data = data.decode()

      if(
            self.data
        and len(self.data) > 32
        and self.data[:32] == self.uuid
        and self.data[45] == '1'
      ):
        self.emit('change', self.data[46:])

  def emit(self, type:str, data:None|str) -> None:
    for callback in self.et.get(type, []):
      callback(data)

    return self

  def get(self) -> None|str:
    return get(self.uuid)

  def off(self, type:str, callback:Callable[[None|str], None]):
    if type in self.et:
      try:
        self.et[type].remove(callback)
      except ValueError:
        pass

      if not self.et[type]:
        del self.et[type]

    return self

  def on(self, type:str, callback:Callable[[None|str], None]) -> None:
    if type not in self.et:
      self.et[type] = []

    self.et[type].append(callback)

    return self

  def read(self) -> None|str:
    return read(self.uuid)

  def set(self, data:str) -> None|int:
    return set(self.uuid, data)

  def write(self, data:str) -> None|int:
    return write(self.uuid, data)
