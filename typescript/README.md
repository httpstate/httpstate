# httpstate (typescript)

## Quick Start

Install

```bash
npm install @httpstate/typescript
```

Import

```bash
import httpstate from '@httpstate/typescript';
```

Pick any valid UUID v4. You can [generate one here](https://uuid.httpstate.com).

We'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3` or `45fb36540e9244daaa21ca409c6bdab3` (without dashes).

Store some data with

```typescript
await httpstate.set('45fb36540e9244daaa21ca409c6bdab3', 'Hi! 👋🏻');
```

and retrieve it with

```typescript
const data = await httpstate.get('45fb36540e9244daaa21ca409c6bdab3');
```

You can also get realtime updates

```typescript
const hs = httpstate('45fb36540e9244daaa21ca409c6bdab3');

hs.on('change', data => console.log(`This will change everytime data is set [${data}].`));
```

That's it! 🐙

## API

### Functions

- `get(uuid)`
  Get state of UUIDv4. Returns `undefined|string`.

- `load()`
  Auto-load state from DOM elements with `httpstate` attribute.

  ```html
  <div httpstate="45fb36540e9244daaa21ca409c6bdab3"></div>
  <img httpstate="45fb36540e9244daaa21ca409c6bdab3">
  ```

  Updates `textContent` (or `src` for `<img>` elements) on data changes.

- `message.unpack(arrayBuffer)`
  Unpack binary WebSocket message into `{ uuid, timestamp, type, value }`.

- `post(uuid, data)`
  Alias for `set`. Returns `undefined|number`.

- `put(uuid, data)`
  Alias for `set`. Returns `undefined|number`.

- `read(uuid)`
  Alias for `get`.

- `set(uuid, data)`
  Set state of UUIDv4. Returns `undefined|number`.

- `write(uuid, data)`
  Alias for `set`.

### HttpState Class

- `httpstate(uuid)`
  Create a reactive state instance of UUIDv4.

- `<HttpState>.data`
  Property with the most up-to-date state value.

<br>

- `<HttpState>.get()`
  Get state. Returns `undefined|string`.
- `<HttpState>.post(data)`
  Alias for `set`.
- `<HttpState>.put(data)`
  Alias for `set`.
- `<HttpState>.read()`
  Alias for `get`.
- `<HttpState>.set(data)`
  Set state. Returns `undefined|number`.
- `<HttpState>.write(data)`
  Alias for `set`.

<br>

- `<HttpState>.addEventListener(type, callback)`
  Subscribe to realtime updates (alias for `on`).
- `<HttpState>.off(type, callback)`
  Unsubscribe from realtime updates.
- `<HttpState>.on(type, callback)`
  Subscribe to realtime updates.
  - `change`: fired when state data changes. Callback receives current data as argument.
- `<HttpState>.removeEventListener(type, callback)`
  Unsubscribe from realtime updates (alias for `off`).

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
