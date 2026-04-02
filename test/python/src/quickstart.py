import datetime
import httpstate
import threading

uuid = '58bff2fcbeb846958f36e7ae5b8a75b0'

print(datetime.datetime.now(datetime.UTC).isoformat(), 'httpstate', uuid)

httpstate.HttpState('58bff2fcbeb846958f36e7ae5b8a75b0').on('change', lambda data : print(datetime.datetime.now(datetime.UTC).isoformat(), 'data', data))

# Not needed per se, only meant to keep the script alive
threading.Event().wait()
