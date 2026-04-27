// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation
import Testing
@testable import HTTPState

// MARK: - Test fixtures

private let endpoint = URL(string: "https://httpstate.com")!
private let webSocketEndpoint = URL(string: "wss://httpstate.com")!

private func makeClient(transport: any Transport) -> HTTPStateClient {
    HTTPStateClient(configuration: HTTPStateConfiguration(
        endpoint: endpoint,
        webSocketEndpoint: webSocketEndpoint,
        transport: transport
    ))
}

private struct StubTransport: Transport {
    var getResult: (body: Data, status: Int) = (Data(), 200)
    var postStatus: Int = 200

    func get(_ url: URL) async throws(HTTPStateError) -> (body: Data, status: Int) {
        getResult
    }

    func post(_ url: URL, body: Data) async throws(HTTPStateError) -> Int {
        postStatus
    }

    func openWebSocket(_ url: URL) async throws(HTTPStateError) -> any WebSocketChannel {
        throw .notConnected
    }
}

private actor RequestRecorder {
    private(set) var gets: [URL] = []
    private(set) var posts: [(url: URL, body: Data)] = []

    func recordGet(_ url: URL) { gets.append(url) }
    func recordPost(url: URL, body: Data) { posts.append((url, body)) }
}

private struct RecordingTransport: Transport {
    let recorder: RequestRecorder
    var getResult: (body: Data, status: Int) = (Data(), 200)
    var postStatus: Int = 200

    func get(_ url: URL) async throws(HTTPStateError) -> (body: Data, status: Int) {
        await recorder.recordGet(url)
        return getResult
    }

    func post(_ url: URL, body: Data) async throws(HTTPStateError) -> Int {
        await recorder.recordPost(url: url, body: body)
        return postStatus
    }

    func openWebSocket(_ url: URL) async throws(HTTPStateError) -> any WebSocketChannel {
        throw .notConnected
    }
}

// MARK: - GET

@Test func getReturnsTrimmedBodyOn200() async throws {
    let client = makeClient(transport: StubTransport(
        getResult: (body: Data("Hi! 👋\n".utf8), status: 200)
    ))
    let value = try await client.get(UUID())
    #expect(value == "Hi! 👋")
}

@Test func getReturnsNilOn404() async throws {
    let client = makeClient(transport: StubTransport(
        getResult: (body: Data(), status: 404)
    ))
    let value = try await client.get(UUID())
    #expect(value == nil)
}

@Test func getReturnsNilOnEmptyOrWhitespaceBody() async throws {
    let client = makeClient(transport: StubTransport(
        getResult: (body: Data("   \n".utf8), status: 200)
    ))
    let value = try await client.get(UUID())
    #expect(value == nil)
}

@Test func getThrowsOnNon2xxNon404() async {
    let client = makeClient(transport: StubTransport(
        getResult: (body: Data(), status: 500)
    ))
    await #expect(throws: HTTPStateError.httpStatus(500)) {
        _ = try await client.get(UUID())
    }
}

@Test func getStringAcceptsDashedAndUndashedAnyCase() async throws {
    let recorder = RequestRecorder()
    let client = makeClient(transport: RecordingTransport(
        recorder: recorder,
        getResult: (Data("ok".utf8), 200)
    ))
    _ = try await client.get("0a3d4b8b-161b-4817-a4f4-3d239e29cec1")
    _ = try await client.get("0A3D4B8B161B4817A4F43D239E29CEC1")
    let urls = await recorder.gets.map(\.absoluteString)
    #expect(urls == [
        "https://httpstate.com/0a3d4b8b161b4817a4f43d239e29cec1",
        "https://httpstate.com/0a3d4b8b161b4817a4f43d239e29cec1"
    ])
}

@Test func getStringThrowsInvalidUUIDOnMalformed() async {
    let client = makeClient(transport: StubTransport())
    await #expect(throws: HTTPStateError.invalidUUID("not-a-uuid")) {
        _ = try await client.get("not-a-uuid")
    }
}

@Test func getStringThrowsInvalidUUIDOnNonHex() async {
    let client = makeClient(transport: StubTransport())
    let bogus = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
    await #expect(throws: HTTPStateError.invalidUUID(bogus)) {
        _ = try await client.get(bogus)
    }
}

// MARK: - SET

@Test func setPostsCanonicalURLWithUTF8Body() async throws {
    let recorder = RequestRecorder()
    let client = makeClient(transport: RecordingTransport(recorder: recorder))
    let id = UUID(uuidString: "0A3D4B8B-161B-4817-A4F4-3D239E29CEC1")!
    try await client.set(id, "Hello 🌍")
    let posts = await recorder.posts
    try #require(posts.count == 1)
    #expect(posts[0].url.absoluteString == "https://httpstate.com/0a3d4b8b161b4817a4f43d239e29cec1")
    #expect(String(data: posts[0].body, encoding: .utf8) == "Hello 🌍")
}

@Test func setNilWritesEmptyBody() async throws {
    let recorder = RequestRecorder()
    let client = makeClient(transport: RecordingTransport(recorder: recorder))
    try await client.set(UUID(), nil)
    let posts = await recorder.posts
    try #require(posts.count == 1)
    #expect(posts[0].body.isEmpty)
}

@Test func setThrowsOnNon2xx() async {
    let client = makeClient(transport: StubTransport(postStatus: 500))
    await #expect(throws: HTTPStateError.httpStatus(500)) {
        try await client.set(UUID(), "x")
    }
}

@Test func setStringThrowsInvalidUUID() async {
    let client = makeClient(transport: StubTransport())
    await #expect(throws: HTTPStateError.invalidUUID("nope")) {
        try await client.set("nope", "x")
    }
}
