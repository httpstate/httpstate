# httpstate (python)

## Install

```bash
pip install httpstate
```

## Quick Start

Install

```bash
pip install httpstate
```

Pick any valid UUID v4. You can [generate one here](https://www.uuidgenerator.net/version4).

We'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3` or `45fb36540e9244daaa21ca409c6bdab3` (without dashes).

Store some data with

```python
httpstate.set('45fb36540e9244daaa21ca409c6bdab3', 'Hi! 👋🏻')
```

and retrieve it with

```python
data = httpstate.get('45fb36540e9244daaa21ca409c6bdab3')
```

You can also get real-time updates

```python
hs = httpstate.HttpState('45fb36540e9244daaa21ca409c6bdab3')

hs.on('change', lambda data: print(f'This will change everytime data is set [{data}].'))
```

That's it! 🐙

## API

### Functions

- `get(uuid)`
  Get state of UUIDv4

- `read(uuid)`
  Alias for `get`

- `set(uuid, data)` - Set state of UUIDv4

- `write(uuid, data)` - Alias for `set`

### HttpState Class

- `HttpState(uuid)` - Create a reactive state instance of UUIDv4
- `state.get()` - Get state
- `state.read()` - Alias for `get`
- `state.set(data)` - Set state
- `state.write(data)` - Alias for `set`

- `state.off(event, callback)` - Unsubscribe from real-time updates
- `state.on(event, callback)` - Subscribe to real-time updates (`change`)

---

## About

Alex Morales, [moralestapia.com](https://moralestapia.com)

Copyright &copy; Alex Morales, 2026

## Contact

Comments, feature requests, etc. are welcome at **inbox @ httpstate.com**

## License

Unless otherwise stated in particular files or directories, this software is free software.

You can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for more information.
