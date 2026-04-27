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
    }

    // MARK: - Snapshot API (one-shot GET)

    /// Fetch the current value for a uuid. Returns `nil` if the server has no
    /// value stored (status 404) or the stored value is empty.
    public func get(_ uuid: UUID) async throws(HTTPStateError) -> String? {
        try await snapshotGet(canonical(uuid))
    }

    /// String overload. Validates the input and throws
    /// ``HTTPStateError/invalidUUID(_:)`` on malformed input before any
    /// network call is issued.
    public func get(_ uuid: String) async throws(HTTPStateError) -> String? {
        guard let canonicalForm = canonicalize(uuid) else {
            throw HTTPStateError.invalidUUID(uuid)
        }
        return try await snapshotGet(canonicalForm)
    }

    // MARK: - Snapshot API (one-shot POST)

    /// Write a value for a uuid. `nil` writes an empty body, matching the
    /// reference client's behavior.
    public func set(_ uuid: UUID, _ data: String?) async throws(HTTPStateError) {
        try await snapshotSet(canonical(uuid), data)
    }

    /// String overload. Validation as in ``get(_:)-String``.
    public func set(_ uuid: String, _ data: String?) async throws(HTTPStateError) {
        guard let canonicalForm = canonicalize(uuid) else {
            throw HTTPStateError.invalidUUID(uuid)
        }
        try await snapshotSet(canonicalForm, data)
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
        fatalError("unimplemented: HTTPStateClient.changes(for:UUID) — WebSocket transport not yet wired")
    }

    /// String overload. This variant **throws** on malformed input because
    /// validation happens synchronously before any stream is created.
    public func changes(for uuid: String) throws(HTTPStateError) -> AsyncStream<String?> {
        fatalError("unimplemented: HTTPStateClient.changes(for:String) — WebSocket transport not yet wired")
    }

    // MARK: - Lifecycle

    /// Close the shared WebSocket and terminate every outstanding stream.
    /// After `shutdown()`, further snapshot calls still work but will open a
    /// fresh connection on the next subscribe. Idempotent.
    public func shutdown() async {
        // No shared state to release until WebSocket support lands.
    }

    // MARK: - Internals

    private func snapshotGet(_ canonicalUUID: String) async throws(HTTPStateError) -> String? {
        let url = configuration.endpoint.appendingPathComponent(canonicalUUID)
        let (body, status) = try await configuration.transport.get(url)
        if status == 404 { return nil }
        guard (200..<300).contains(status) else {
            throw HTTPStateError.httpStatus(status)
        }
        guard let decoded = String(data: body, encoding: .utf8) else {
            throw HTTPStateError.decodingFailed(reason: "response body is not valid UTF-8")
        }
        let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func snapshotSet(_ canonicalUUID: String, _ data: String?) async throws(HTTPStateError) {
        let url = configuration.endpoint.appendingPathComponent(canonicalUUID)
        let body = data.map { Data($0.utf8) } ?? Data()
        let status = try await configuration.transport.post(url, body: body)
        guard (200..<300).contains(status) else {
            throw HTTPStateError.httpStatus(status)
        }
    }
}

/// Canonical wire format for a uuid: 32 lowercase hex chars, no dashes.
/// Matches the form the reference clients send and what the author's iOS app
/// stores in `@AppStorage`.
private func canonical(_ uuid: UUID) -> String {
    uuid.uuidString.lowercased().replacingOccurrences(of: "-", with: "")
}

/// Validate and normalize a uuid string. Accepts both 36-char dashed and
/// 32-char undashed forms, any case. Returns `nil` for anything else.
private func canonicalize(_ string: String) -> String? {
    let stripped = string.replacingOccurrences(of: "-", with: "").lowercased()
    guard stripped.count == 32, stripped.allSatisfy(\.isHexDigit) else {
        return nil
    }
    return stripped
}
