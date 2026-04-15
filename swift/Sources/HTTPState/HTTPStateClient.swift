// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation

/// The primary entry point for talking to an httpstate endpoint.
///
/// `HTTPStateClient` is an actor: it owns the shared WebSocket, multiplexes
/// subscriptions across many uuids, and ref-counts callers so one logical
/// subscription is shared by any number of ``changes(for:)`` consumers.
///
/// # Two ways to use it
///
/// **Snapshot** — a one-shot read or write, ideal for Widgets, Shortcuts, and
/// background refresh where holding a socket is wasteful or impossible:
///
/// ```swift
/// let client = HTTPStateClient(configuration: .default)
/// let status = try await client.get(bikeLockUUID)
/// ```
///
/// **Stream** — a live subscription that emits every server-side change as
/// long as the returned `AsyncStream` is iterated. The underlying socket is
/// torn down automatically when the last stream for a uuid terminates:
///
/// ```swift
/// for await update in await client.changes(for: bikeLockUUID) {
///     render(update)
/// }
/// ```
///
/// `changes(for:)` does **not** throw on transport failure — the reconnect
/// policy handles it internally and the stream keeps delivering whatever the
/// server most recently published. Only ``shutdown()`` terminates a stream.
public actor HTTPStateClient {
    /// The configuration this client was built with. Immutable after init.
    public nonisolated let configuration: HTTPStateConfiguration

    /// Construct a client. Configuration is required — there is no shared
    /// default instance, on purpose.
    public init(configuration: HTTPStateConfiguration) {
        self.configuration = configuration
        fatalError("unimplemented: HTTPStateClient.init")
    }

    // MARK: - Snapshot API (one-shot GET)

    /// Fetch the current value for a uuid. Returns `nil` if the server has no
    /// value stored (status 404) or the stored value is empty.
    public func get(_ uuid: UUID) async throws(HTTPStateError) -> String? {
        fatalError("unimplemented: HTTPStateClient.get(UUID)")
    }

    /// String overload. Validates the input and throws
    /// ``HTTPStateError/invalidUUID(_:)`` on malformed input before any
    /// network call is issued.
    public func get(_ uuid: String) async throws(HTTPStateError) -> String? {
        fatalError("unimplemented: HTTPStateClient.get(String)")
    }

    // MARK: - Snapshot API (one-shot POST)

    /// Write a value for a uuid. `nil` writes an empty body, matching the
    /// reference client's behavior.
    public func set(_ uuid: UUID, _ data: String?) async throws(HTTPStateError) {
        fatalError("unimplemented: HTTPStateClient.set(UUID,_:)")
    }

    /// String overload. Validation as in ``get(_:)-String``.
    public func set(_ uuid: String, _ data: String?) async throws(HTTPStateError) {
        fatalError("unimplemented: HTTPStateClient.set(String,_:)")
    }

    // MARK: - Stream API (live subscription)

    /// Observe server-side changes for a uuid. Each call returns an
    /// independent `AsyncStream`; all streams for the same uuid share one
    /// underlying WebSocket subscription. The stream is never-ending by
    /// design — it terminates only on ``shutdown()`` or when the consumer
    /// cancels its task.
    ///
    /// Emits `nil` when the server reports an empty/cleared value.
    public func changes(for uuid: UUID) -> AsyncStream<String?> {
        fatalError("unimplemented: HTTPStateClient.changes(for:UUID)")
    }

    /// String overload. This variant **throws** on malformed input because
    /// validation happens synchronously before any stream is created.
    public func changes(for uuid: String) throws(HTTPStateError) -> AsyncStream<String?> {
        fatalError("unimplemented: HTTPStateClient.changes(for:String)")
    }

    // MARK: - Lifecycle

    /// Close the shared WebSocket and terminate every outstanding stream.
    /// After `shutdown()`, further snapshot calls still work but will open a
    /// fresh connection on the next subscribe. Idempotent.
    public func shutdown() async {
        fatalError("unimplemented: HTTPStateClient.shutdown")
    }
}
