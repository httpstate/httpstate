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
        let pair: (Data, URLResponse)
        do {
            pair = try await session.data(from: url)
        } catch {
            throw HTTPStateError.transport(description: String(describing: error))
        }
        guard let http = pair.1 as? HTTPURLResponse else {
            throw HTTPStateError.transport(description: "non-HTTP response")
        }
        return (body: pair.0, status: http.statusCode)
    }

    public func post(_ url: URL, body: Data) async throws(HTTPStateError) -> Int {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let pair: (Data, URLResponse)
        do {
            pair = try await session.data(for: request)
        } catch {
            throw HTTPStateError.transport(description: String(describing: error))
        }
        guard let http = pair.1 as? HTTPURLResponse else {
            throw HTTPStateError.transport(description: "non-HTTP response")
        }
        return http.statusCode
    }

    public func openWebSocket(_ url: URL) async throws(HTTPStateError) -> any WebSocketChannel {
        NoOpWebSocketChannel()
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
