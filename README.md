<div align="center">
  <img alt="httpstate mascot" height="256" src="assets/mascot.256x256.png" width="256">

  <h1>httpstate</h1>

  <p>The missing reactive layer for your applications.</p>

  <p>Create interactive experiences with a couple lines of code.</p>

  <p>Learn more at <a href="https://httpstate.com" target="_blank">httpstate.com</a>.</p>
</div>

## Quick Start (browser, node.js)

Install from CDN

```html
<script src="https://cdn.jsdelivr.net/npm/@httpstate/typescript/dist/index.global.js" type="text/javascript"></script>
```

or use npm

```bash
npm install httpstate
```

Pick any valid UUID v4, we'll use `45fb3654-0e92-44da-aa21-ca409c6bdab3`.

Store some data with:

```js
httpstate.set('45fb3654-0e92-44da-aa21-ca409c6bdab3', 'Hi! 👋🏻')
```

then retrieve it with:

```js
httpstate.get('45fb3654-0e92-44da-aa21-ca409c6bdab3')
```

You can also get real-time updates:

```js
const hs = httpstate('45fb3654-0e92-44da-aa21-ca409c6bdab3');

hs.on('change', data => {
  console.log('This will change everytime a new value is set', data);
});
```

That's it! 🐙

## or choose your favorite language

### Javascript / Typescript ([typescript](./typescript))

Browser and server (node.js, deno, bun) compatible clients.

[API and Docs](./typescript)

### React ([react](./react))

`useHttpState()` is a drop-in replacement to `useState()`

[API and Docs](./react)

### Go ([go](./go))

...

[API and Docs](./go)

### Python ([python](./python))

...

[API and Docs](./python)

### Rust ([rust](./rust))

...

[API and Docs](./rust)

## Learn

Basics: [...]

Community: [...]

Cookbook: Refer to [...]

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
