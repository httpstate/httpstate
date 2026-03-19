# httpstate (react)

## Quick Start

Install

```bash
npm install @httpstate/react
```

Import

```bash
import { useHttpState } from '@httpstate/react';
```

Pick any valid UUID v4. You can [generate one here](https://uuid.httpstate.com).

We'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3` or `45fb36540e9244daaa21ca409c6bdab3` (without dashes).

Use `useHttpState(uuid)` as you would do with a React `useState()` hook.

```tsx
const [state, setState] = useHttpState('45fb36540e9244daaa21ca409c6bdab3');

setState('Hi! 👋🏻');
```

That's it! 🐙

## API

### Hook

- `useHttpState(uuid)`
  Create a reactive state instance of UUIDv4.
  - `uuid`: The UUID v4 string.

  - Returns `[state, setState]` where:
    - `state`: The current value (undefined | string).
    - `setState`: The set function that lets you update the state to a different value.

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
