// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation

/// A bidirectional binary WebSocket owned by a ``Transport``.
///
/// Intentionally minimal — the client only needs to send text/data frames
/// (for keepalive + subscription open) and read frames until close. Frame
/// framing and reconnect are handled above this protocol.
public protocol WebSocketChannel: Sendable {
    /// Send a text frame. Used for the subscription-open handshake and the
    /// `"0"` keepalive ping.
    func send(text: String) async throws(HTTPStateError)

    /// Send a binary frame.
    func send(data: Data) async throws(HTTPStateError)

    /// Await the next inbound frame. Returns `nil` on clean close.
    func receive() async throws(HTTPStateError) -> WebSocketFrame?

    /// Close the channel. Idempotent.
    func close() async
}

/// A received WebSocket frame.
public enum WebSocketFrame: Sendable, Equatable {
    case text(String)
    case data(Data)
}

/// A `WebSocketChannel` that does nothing useful. `receive()` returns `nil`
/// immediately — i.e. the channel is already closed — so any consumer's
/// frame loop terminates on the first iteration. `send` and `close` accept
/// their inputs and drop them.
///
/// Returned by transports that haven't wired up a real WebSocket yet, so
/// callers can exercise the streaming API without crashing.
public struct NoOpWebSocketChannel: WebSocketChannel {
    public init() {}

    public func send(text: String) async throws(HTTPStateError) {}
    public func send(data: Data) async throws(HTTPStateError) {}
    public func receive() async throws(HTTPStateError) -> WebSocketFrame? { nil }
    public func close() async {}
}
