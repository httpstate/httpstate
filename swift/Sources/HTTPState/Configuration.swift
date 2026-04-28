// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation

/// First-class configuration for an ``HTTPStateClient``.
///
/// Consumers build one of these explicitly at startup and hand it to the
/// client's initializer. There is no hidden `.shared` default instance —
/// construction is always deliberate so testing and multi-endpoint setups
/// (staging, self-hosted) don't have to fight global state.
public struct HTTPStateConfiguration: Sendable {
    /// Base URL for HTTP `GET`/`POST` operations. Uuids are appended as the
    /// final path component.
    public var endpoint: URL

    /// Base URL for the WebSocket subscription channel.
    public var webSocketEndpoint: URL

    /// Transport used for every network operation. Pluggable so consumers can
    /// inject a mock in tests or swap URLSession for a server-side backend.
    public var transport: any Transport

    /// Reconnect behavior for the WebSocket. See ``ReconnectPolicy``.
    public var reconnect: ReconnectPolicy

    /// Interval between WebSocket keepalive pings. Matches the reference
    /// client's 30s cadence.
    public var pingInterval: Duration

    public init(
        endpoint: URL,
        webSocketEndpoint: URL,
        transport: any Transport,
        reconnect: ReconnectPolicy = .default,
        pingInterval: Duration = .seconds(30)
    ) {
        self.endpoint = endpoint
        self.webSocketEndpoint = webSocketEndpoint
        self.transport = transport
        self.reconnect = reconnect
        self.pingInterval = pingInterval
    }
}

/// Exponential-backoff policy for WebSocket reconnection.
///
/// Defaults mirror the reference TypeScript client: ~1s initial delay,
/// doubling, capped at ~60s.
public struct ReconnectPolicy: Sendable, Equatable {
    public var initialDelay: Duration
    public var maxDelay: Duration
    public var multiplier: Double

    public init(initialDelay: Duration, maxDelay: Duration, multiplier: Double) {
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }

    /// ~1s → ~60s exponential backoff.
    public static let `default` = ReconnectPolicy(
        initialDelay: .milliseconds(1024),
        maxDelay: .seconds(60),
        multiplier: 2.0
    )

    /// Disables automatic reconnect. Intended for tests or short-lived tools
    /// that want to fail loudly on disconnect.
    public static let disabled = ReconnectPolicy(
        initialDelay: .seconds(0),
        maxDelay: .seconds(0),
        multiplier: 1.0
    )
}
