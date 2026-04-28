// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation

/// Pluggable network surface used by ``HTTPStateClient``.
///
/// The core package ships no concrete implementation — the default
/// URLSession-backed transport lives in the `HTTPStateTransportURLSession`
/// target so the core remains Foundation-light and Linux-portable.
///
/// Implementations must be `Sendable`; they will be stored inside an actor
/// and called from arbitrary tasks.
public protocol Transport: Sendable {
    /// Perform an HTTP `GET`. Returns the response body and status code.
    /// Implementations should not translate non-2xx into errors — the client
    /// inspects the status itself.
    func get(_ url: URL) async throws(HTTPStateError) -> (body: Data, status: Int)

    /// Perform an HTTP `POST` with a `text/plain; charset=utf-8` body.
    /// Returns the response status code.
    func post(_ url: URL, body: Data) async throws(HTTPStateError) -> Int

    /// Open a binary WebSocket to the given URL. The returned channel is
    /// owned by the caller; closing the channel closes the socket.
    func openWebSocket(_ url: URL) async throws(HTTPStateError) -> any WebSocketChannel
}
