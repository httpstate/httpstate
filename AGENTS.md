# AGENTS.md

## What is httpstate?

httpstate is a reactive state layer for applications. You bind state values to UUID v4 keys, store them via the REST API at `https://httpstate.com`, and retrieve them from anywhere. Realtime updates are delivered through WebSocket connections. It is free, requires no authentication, and values are limited to 128 bytes.

## REST API

### Base URL

```
https://httpstate.com
```

### GET `/:uuid`

Retrieve the current value stored at a UUID v4.

- UUIDs can be full format (`45fb3654-0e92-44da-aa21-ca409c6bdab3`) or short format (`45fb36540e9244daaa21ca409c6bdab3`).
- UUIDs can optionally include a path suffix of 1-8 hex chars (e.g. `45fb36540e9244daaa21ca409c6bdab3/0`).
- **Response `200`**: Body contains the stored value as `text/plain;charset=UTF-8`.
- **Response `404`**: UUID has no stored value.
- Response headers include `ETag` (timestamp in ms) and `Last-Modified`.

```
curl https://httpstate.com/45fb36540e9244daaa21ca409c6bdab3
```

### POST `/:uuid` (also PUT)

Store a value at a UUID v4. If the UUID already has a value, it is overwritten.

- Content-Type: `text/plain;charset=UTF-8` (default).
- Content-Type: `application/x-www-form-urlencoded` — form data is parsed into JSON if there are multiple keys or a single non-empty key. When the `Referer` header is also present, the server responds with a `302` redirect back to the referer (enables plain HTML form submissions).
- Maximum body size: **128 bytes**. Larger requests return `413 Content Too Large`.
- **Response `200`**: Value was stored. Headers include `ETag` and `Last-Modified`.
- **Response `304`**: Conditional write precondition was not met.
- **Response `412`**: `If-Match` or `If-None-Match` precondition failed.
- **Response `429`**: Rate limit exceeded.

```
curl -X POST -d "Hi!" https://httpstate.com/45fb36540e9244daaa21ca409c6bdab3
```

### DELETE `/:uuid`

Returns `200`. Inactive UUIDs are pruned after ~1 month.

### OPTIONS `/*`

Returns `200` with CORS headers. All responses include `Access-Control-Allow-Origin: *` and `Access-Control-Allow-Methods: GET, POST`.

### Inbound Channels

| Channel | How it works |
|---|---|
| **Email** (`mail.httpstate.com`) | Send email; UUID extracted from the `to` address (before `@`) or subject line; body is stored as the value |
| **SMS** (`sms.httpstate.com`) | Send SMS in format `<UUID> <message>`; message is stored as the value |

## Conditional Writes & Operations

The POST endpoint supports special headers for conditional and atomic operations:

### Conditional Headers

| Header | Behavior |
|---|---|
| `If-Match: <etag>` | Only succeed if the current ETag matches |
| `If-None-Match: <etag>` | Only succeed if the current ETag does not match |

### Operation Header

Set `Operation: <type>` to perform an atomic read-modify-write:

| Operation | Description |
|---|---|
| `add` | Adds the posted number to the current value |
| `append` | Appends the posted value to the current value (truncated to 128 bytes) |
| `merge` | Merges the posted JSON object into the current JSON object |
| `prepend` | Prepends the posted value to the current value (truncated to 128 bytes) |
| `toggle` | Toggles between `0` and `1` |

### Conditional Write Headers

| Header | Behavior |
|---|---|
| `Write-If-Equals: <value>` | Only write if current value equals `<value>` |
| `Write-If-Not-Equals: <value>` | Only write if current value does not equal `<value>` |
| `Write-If-Greater-Than: <number>` | Only write if current numeric value is greater than `<number>` |
| `Write-If-Less-Than: <number>` | Only write if current numeric value is less than `<number>` |

These return `304 Not Modified` if the condition is not met.

## Idempotency

Include an `Idempotency-Key: <key>` header with POST requests. Duplicate keys within 24 hours return `409 Conflict`.

## Rate Limiting

Up to 8 requests per second with a burst of 128. Exceeding the limit returns `429 Too Many Requests`.

## WebSocket Protocol

Connect to `wss://httpstate.com`.

### Subscribing

After connecting, send:

```json
{"open": "<uuid>"}
```

The server responds with the current value and subscribes you to future changes for that UUID.

### Receiving Updates

Messages are binary with this packed format:

```
[1 byte: UUID length] [N bytes: UUID] [8 bytes: timestamp (uint64 BE)] [1 byte: type] [remaining: value]
```

- Type `0`: application/octet-stream
- Type `1`: text/plain;charset=UTF-8 (the common case)

### Ping

Send a ping frame or the text message `"0"` to keep the connection alive.

### Reconnection

Reconnect with exponential backoff when the connection drops while subscriptions are active.

## UUIDv4 Format

The API accepts UUIDs in these forms:
- Full: `45fb3654-0e92-44da-aa21-ca409c6bdab3` (36 chars)
- Short: `45fb36540e9244daaa21ca409c6bdab3` (32 hex chars, no dashes)
- Short with path: `45fb36540e9244daaa21ca409c6bdab3/0` through `/ffffffff` (1-8 hex path chars)

Generate a UUID at https://uuid.httpstate.com

## Client Libraries

All client libraries share the same core API:

### Top-level functions

| Function | Description |
|---|---|
| `get(uuid)` / `read(uuid)` | Retrieve value for a UUID |
| `set(uuid, data)` / `write(uuid, data)` / `post(uuid, data)` / `put(uuid, data)` | Store a value at a UUID |

Available in: TypeScript, Python, Go, Java, Ruby, Rust.

### Instance-based (realtime)

Create an instance with `httpstate(uuid)` (or `HttpState(uuid)` / `new HttpState(uuid)`). The instance:

1. Opens a WebSocket connection and subscribes to the UUID
2. Calls `get()` to fetch the initial value
3. Emits `change` events whenever the value updates

Instance methods: `get()`, `set(data)`, `on(type, callback)`, `off(type, callback)`, `emit(type, data)`, `delete()`.

### Browser

- `httpstate.load()` — finds all DOM elements with `httpstate="<uuid>"` attributes, subscribes to changes, and updates `textContent` (or `src` for `<img>`) in real time.

### React

```tsx
const [state, setState] = useHttpState('45fb36540e9244daaa21ca409c6bdab3');
setState('Hi!');
```

Returns `[state, setState]` like `useState()`.

### Installing

| Language | Install |
|---|---|
| TypeScript / JS | `npm install @httpstate/typescript` |
| React | `npm install @httpstate/react` |
| Python | `pip install httpstate` |
| Go | `go get github.com/httpstate/httpstate/go` |
| Ruby | `gem install httpstate` |
| Rust | `cargo add httpstate` |
| Java | See `java/src/com/httpstate/HttpState.java` in this repo |

### Browser CDN

```html
<script src="https://cdn.jsdelivr.net/npm/@httpstate/typescript/dist/index.global.js"></script>
```

Or as an ES module:

```js
import httpstate from 'https://cdn.jsdelivr.net/npm/@httpstate/typescript/dist/index.esm.js';
```
