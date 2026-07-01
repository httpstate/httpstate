# HTTPState, https://httpstate.com/
# Copyright (C) Alex Morales, 2026

# Unless otherwise stated in particular files or directories, this software is free software.
# You can redistribute it and/or modify it under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.

# pip install httpstate

import datetime
import httpstate
import threading

uuid = '58bff2fcbeb846958f36e7ae5b8a75b0'

print(datetime.datetime.now(datetime.UTC).isoformat(), 'httpstate', uuid)

httpstate.HTTPState('58bff2fcbeb846958f36e7ae5b8a75b0').on('change', lambda data : print(datetime.datetime.now(datetime.UTC).isoformat(), 'data', data))

# Not needed per se, only meant to keep the script alive
threading.Event().wait()
