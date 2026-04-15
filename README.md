<div align="center">
  <img alt="httpstate mascot" height="256" src="assets/mascot.256x256.png" width="256">

  <h1>httpstate</h1>

  <p><strong>httpstate</strong> is the missing reactive layer for all your applications.</p>

  <p>Store and retrieve <strong>state</strong> by binding it to any UUID.</p>

  <p>Create interactive experiences with a couple lines of code.</p>

  <p>More at <a href="https://httpstate.com" target="_blank">httpstate.com</a>.</p>
</div>

## Quick Start (browser, node.js)

Install from CDN (Script Tag)

```html
<script src="https://cdn.jsdelivr.net/npm/@httpstate/typescript/dist/index.global.js" type="text/javascript"></script>
```

or import from CDN (ES Module)

```js
import httpstate from 'https://cdn.jsdelivr.net/npm/@httpstate/typescript@0.0.42/dist/index.esm.js';
```

or install from npm

```html
npm install @httpstate/typescript
```

and then import

```js
import * as httpstate from '@httpstate/typescript';
```

Pick any valid UUID v4. You can [generate one here](https://uuid.httpstate.com).

We'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3` or `45fb36540e9244daaa21ca409c6bdab3` (works without dashes).

Store some data with

```js
httpstate.set('45fb36540e9244daaa21ca409c6bdab3', 'Hi! 👋🏻');
```

and retrieve it with

```js
const data = await httpstate.get('45fb36540e9244daaa21ca409c6bdab3');
```

You can also get realtime updates

```js
import httpstate from '@httpstate/typescript';

const hs = httpstate('45fb36540e9244daaa21ca409c6bdab3');

hs.on('change', data => console.log(data));
```

That's it! 🐙

## Realtime Updates

All client libraries support realtime updates via WebSocket. Create a reactive instance bound to a UUID and subscribe to `change` events:

```js
const hs = httpstate('45fb36540e9244daaa21ca409c6bdab3');

hs.on('change', data => console.log(data));
```

Any client that calls `set()` on the same UUID will trigger a `change` event across all connected instances — across devices, languages, and platforms. The TypeScript client uses a shared WebSocket connection with automatic reconnection and exponential backoff.

## httpstate in your favorite language

### <img alt="JS" height="32" src="assets/JS.svg" width="32"/> Javascript / Typescript ([typescript](./typescript))

Browser and server (node.js, deno, bun) compatible clients.

```bash
npm install @httpstate/typescript
```

[API and Docs](./typescript)

### <img alt="React" height="32" src="assets/React.svg" width="32"/> React ([react](./react))

```bash
npm install @httpstate/react
```

Use it like `useState()`:

```js
const [state, setState] = useHttpState('45fb36540e9244daaa21ca409c6bdab3');

// state — reactive value, auto-updates on change
// setState(data) — writes data via httpstate.set()
```

[API and Docs](./react)

### <img alt="Go" height="32" src="assets/Go.png" width="32"/> Go ([go](./go))

```bash
go get github.com/httpstate/httpstate/go
```

[API and Docs](./go)

### <img alt="Java" height="32" src="assets/Java.svg" width="32"/> Java ([java](./java))

```bash
See, https://github.com/httpstate/httpstate/blob/master/java/src/com/httpstate/HttpState.java
```

[API and Docs](./java)

### <img alt="Python" height="32" src="assets/python.png" width="32"/> Python ([python](./python))

```bash
pip install httpstate
```

[API and Docs](./python)

### <img alt="Ruby" height="24" src="assets/Ruby.svg" width="24"/> Ruby ([ruby](./ruby))

```bash
gem install httpstate
```

[API and Docs](./ruby)

### <img alt="Rust" height="32" src="assets/Rust.svg" width="32"/> Rust ([rust](./rust))

```bash
cargo add httpstate
```

[API and Docs](./rust)

### iOS ([iOS](./iOS))

Native app with live data display, Home Screen widget, and Lock Screen widget.

### macOS ([macOS](./macOS))

Native app with live data display and widget.

---

## Learn

Community: [...]

Cookbook: [...]

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
