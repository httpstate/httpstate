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

You can also get real-time updates

```typescript
const hs = httpstate('45fb36540e9244daaa21ca409c6bdab3');

hs.on('change', data => console.log(`This will change everytime data is set [${data}].`));
```

That's it! 🐙

## API

### Functions

- `get(uuid)`
  Get state of UUIDv4.

- `load()`
  Auto-load state from DOM elements with `httpstate` attribute.

- `post(uuid, data)`
  Alias for `set`.

- `read(uuid)`
  Alias for `get`.

- `set(uuid, data)`
  Set state of UUIDv4.

- `write(uuid, data)`
  Alias for `set`.

### HttpState Class

- `httpstate(uuid)`
  Create a reactive state instance of UUIDv4.

- `<HttpState>.data`
  Property with the most up-to-date state value.

<br>

- `<HttpState>.get()`
  Get state.
- `<HttpState>.post(data)`
  Alias for `set`.
- `<HttpState>.read()`
  Alias for `get`.
- `<HttpState>.set(data)`
  Set state.
- `<HttpState>.write(data)`
  Alias for `set`.

<br>

- `<HttpState>.addEventListener(type, callback)`
  Subscribe to real-time updates (alias for `on`).
- `<HttpState>.off(type, callback)`
  Unsubscribe from real-time updates.
- `<HttpState>.on(type, callback)`
  Subscribe to real-time updates.
  - `change`: fired when state data changes. Callback receives current data as argument.
- `<HttpState>.removeEventListener(type, callback)`
  Unsubscribe from real-time updates (alias for `off`).

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
