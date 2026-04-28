// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation

/// Errors surfaced by the HTTPState client and its transports.
///
/// Exhaustive by design so that typed-throws callers can `switch` without a
/// `@unknown default`. Adding a case is a source-breaking change on purpose —
/// we want consumers to notice new failure modes.
public enum HTTPStateError: Error, Sendable, Equatable {
    /// The supplied string was not a valid UUID. Only thrown from the
    /// `String`-based overloads; the `UUID`-typed overloads cannot hit this.
    /// Associated value is the offending input, verbatim.
    case invalidUUID(String)

    /// The underlying transport failed before an HTTP response was received.
    /// Wraps the concrete transport error (e.g. `URLError`) as a string so the
    /// error type stays `Sendable`/`Equatable` without leaking Foundation types.
    case transport(description: String)

    /// The server responded, but with a non-success status code.
    case httpStatus(Int)

    /// Received a payload the client could not decode (e.g. a malformed
    /// WebSocket frame, or a response body that isn't valid UTF-8).
    case decodingFailed(reason: String)

    /// An operation required an open WebSocket and none was available
    /// (e.g. after `shutdown()`).
    case notConnected
}
