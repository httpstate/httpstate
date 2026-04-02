import asyncio
import datetime
import time

import httpstate

uuid = '06ee9a21a70b49c3bcffc335995cf2b4'

print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid)

# {
data = str(int(time.time()*1000))

httpstate.set(uuid, data)
if(httpstate.get(uuid) == data):
  print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid, '(static)      get/set', '✅')
# }

# {
data = str(int(time.time()*1000))

httpstate.write(uuid, data)
if(httpstate.read(uuid) == data):
  print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid, '(static)   read/write', '✅')
# }

# {
async def instance_load():
  data = str(int(time.time()*1000))

  httpstate.set(uuid, data)

  running_loop = asyncio.get_running_loop()
  f = running_loop.create_future()
  
  async def task():
    _ = httpstate.HttpState(uuid)

    def callback(__=None):
      if(_.data == data):
        print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid, '(instance.load)  data', '✅')

        _.destroy()

        running_loop.call_soon_threadsafe(lambda : f.set_result(None))

    _.on('change', callback)

  asyncio.create_task(task())

  await f

asyncio.run(instance_load())
# }

# {
data = str(int(time.time()*1000))

_ = httpstate.HttpState(uuid)
_.set(data)
if(_.get() == data):
  print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid, '(instance)    get/set', '✅')
# }

# {
data = str(int(time.time()*1000))

_ = httpstate.HttpState(uuid)
_.write(data)
if(_.read() == data):
  print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid, '(instance) read/write', '✅')
# }

# {
async def instance_change():
  data = str(int(time.time()*1000))

  running_loop = asyncio.get_running_loop()
  f = running_loop.create_future()
  
  async def task():
    _ = httpstate.HttpState(uuid)

    def callback(__=None):
      if(_.data == data):
        print(datetime.datetime.now(datetime.UTC).isoformat(timespec="milliseconds"), '@httpstate/typescript', uuid, '(instance)     change', '✅')

        _.destroy()

        running_loop.call_soon_threadsafe(lambda : f.set_result(None))

    _.on('change', callback).on('open', lambda : _.set(data))

  asyncio.create_task(task())

  await f

asyncio.run(instance_change())
# }
