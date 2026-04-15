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
