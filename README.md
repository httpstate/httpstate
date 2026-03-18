<div align="center">
  <img alt="httpstate mascot" height="256" src="assets/mascot.256x256.png" width="256">

  <h1>httpstate</h1>

  <p>The missing reactive layer for all your applications.</p>

  <p>Create interactive experiences with a couple lines of code.</p>

  <p>More at <a href="https://httpstate.com" target="_blank">httpstate.com</a>.</p>
</div>

## Quick Start (browser, node.js)

Install from CDN

```html
<script src="https://cdn.jsdelivr.net/npm/@httpstate/typescript/dist/index.global.js" type="text/javascript"></script>
```

or from npm

```bash
npm install @httpstate/typescript
```

Import (not needed if you use the CDN)

```bash
import * as httpstate from '@httpstate/typescript';
```

Pick any valid UUID v4. You can [generate one here](https://uuid.httpstate.com).

We'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3` or `45fb36540e9244daaa21ca409c6bdab3` (without dashes).

Store some data with

```js
httpstate.set('45fb36540e9244daaa21ca409c6bdab3', 'Hi! 👋🏻');
```

and retrieve it with

```js
const data = await httpstate.get('45fb36540e9244daaa21ca409c6bdab3');
```

You can also get real-time updates

```js
import httpstate from '@httpstate/typescript';

const hs = httpstate('45fb36540e9244daaa21ca409c6bdab3');

hs.on('change', data => {
  console.log(`This will change everytime data is set [${data}].`);
});
```

That's it! 🐙

## httpstate in your favorite language

Browser and server (node.js, deno, bun) compatible clients.

### <img alt="JS" height="32" src="assets/JS.svg" width="32"/> Javascript / Typescript ([typescript](./typescript))

```bash
npm install @httpstate/typescript
```

[API and Docs](./typescript)

### <img alt="React" height="32" src="assets/React.svg" width="32"/> React ([react](./react))

```bash
npm install @httpstate/react
```

Then `useHttpState(uuid)` as you would `useState()`.

[API and Docs](./react)

### Go ([go](./go))

```bash
go get github.com/httpstate/httpstate/go
```

[API and Docs](./go)

### Java ([java](./java))

```bash
[...]
```

[API and Docs](./java)

### Python ([python](./python))

```bash
pip install httpstate
```

[API and Docs](./python)

### Ruby ([ruby](./ruby))

```bash
[...]
```

[API and Docs](./ruby)

### Rust ([rust](./rust))

```bash
cargo add httpstate
```

[API and Docs](./rust)

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
