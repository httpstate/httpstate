// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation
import HTTPState

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Default ``Transport`` implementation built on `URLSession` and
/// `URLSessionWebSocketTask`.
///
/// Darwin-first: on Apple platforms this is the ideal path. On Linux it
/// relies on swift-corelibs-foundation's URLSession, which is functional but
/// historically spottier for WebSockets — use the protocol-based swap-out if
/// that becomes a problem in a given deployment.
public struct URLSessionTransport: Transport {
    public let session: URLSession

    /// Construct with an explicit session. Consumers who need custom
    /// timeouts, TLS pinning, or proxy config build their own
    /// `URLSessionConfiguration` and pass the resulting session here.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(_ url: URL) async throws(HTTPStateError) -> (body: Data, status: Int) {
        fatalError("unimplemented: URLSessionTransport.get")
    }

    public func post(_ url: URL, body: Data) async throws(HTTPStateError) -> Int {
        fatalError("unimplemented: URLSessionTransport.post")
    }

    public func openWebSocket(_ url: URL) async throws(HTTPStateError) -> any WebSocketChannel {
        fatalError("unimplemented: URLSessionTransport.openWebSocket")
    }
}

/// Convenience ``HTTPStateConfiguration`` preset targeting the canonical
/// `httpstate.com` service via URLSession. The umbrella `HTTPStateClient`
/// target re-exports this as a module-level default.
extension HTTPStateConfiguration {
    /// `https://httpstate.com` + `wss://httpstate.com`, URLSession transport,
    /// default reconnect + ping.
    public static var httpstateDotCom: HTTPStateConfiguration {
        HTTPStateConfiguration(
            endpoint: URL(string: "https://httpstate.com")!,
            webSocketEndpoint: URL(string: "wss://httpstate.com")!,
            transport: URLSessionTransport()
        )
    }
}
