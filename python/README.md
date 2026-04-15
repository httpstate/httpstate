# httpstate (python)

## Quick Start

Install

```bash
pip install httpstate
```

Import

```bash
import httpstate
```

Pick any valid UUID v4. You can [generate one here](https://uuid.httpstate.com).

We'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3` or `45fb36540e9244daaa21ca409c6bdab3` (without dashes).

Store some data with

```python
httpstate.set('45fb36540e9244daaa21ca409c6bdab3', 'Hi! 👋🏻')
```

and retrieve it with

```python
data = httpstate.get('45fb36540e9244daaa21ca409c6bdab3')
```

You can also get realtime updates

```python
hs = httpstate.HttpState('45fb36540e9244daaa21ca409c6bdab3')

hs.on('change', lambda data: print(f'This will change everytime data is set [{data}].'))
```

That's it! 🐙

## API

### Functions

- `get(uuid)`
  Get state of UUIDv4. Returns `None|str`.

- `message.unpack(bytes)`
  Unpack binary WebSocket message into `MessageType(uuid, timestamp, type, value)`.

- `post(uuid, data=None)`
  Alias for `set`. Returns `None|int`.

- `put(uuid, data=None)`
  Alias for `set`. Returns `None|int`.

- `read(uuid)`
  Alias for `get`.

- `set(uuid, data=None)`
  Set state of UUIDv4. Returns `None|int`. If `data` is `None`, defaults to `''`.

- `write(uuid, data=None)`
  Alias for `set`.

### HttpState Class

- `HttpState(uuid)`
  Create a reactive state instance of UUIDv4.
- `<HttpState>.data`
  Property with the most up-to-date state value.

<br>

- `<HttpState>.get()`
  Get state. Returns `None|str`.
- `<HttpState>.post(data=None)`
  Alias for `set`.
- `<HttpState>.put(data=None)`
  Alias for `set`.
- `<HttpState>.read()`
  Alias for `get`.
- `<HttpState>.set(data=None)`
  Set state. Returns `None|int`. If `data` is `None`, defaults to `''`.
- `<HttpState>.write(data=None)`
  Alias for `set`.

<br>

- `<HttpState>.off(type, callback)`
  Unsubscribe from realtime updates.
- `<HttpState>.on(type, callback)`
  Subscribe to realtime updates.
  - `change`: fired when state data changes. Callback receives current data as argument.

<br>

- `<HttpState>.delete()`
  Cleanup and delete the instance.

---

## About

Alex Morales, [moralestapia.com](https://moralestapia.com)

Copyright &copy; Alex Morales, 2026

## Contact

Comments, feature requests, etc. are welcome at **inbox @ httpstate.com**.

## License

Unless otherwise stated in particular files or directories, this software is free software.

You can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for more information.
