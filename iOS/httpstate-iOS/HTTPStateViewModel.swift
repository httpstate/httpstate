// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import Foundation
import HTTPStateClient
import Observation
import WidgetKit

@MainActor
@Observable
final class HTTPStateViewModel {
    var uuid: String {
        didSet { defaults.set(uuid, forKey: Keys.uuid) }
    }

    var value: String = "—"
    var retrievedAt: Date = .now
    var pendingValue: String = ""
    var isWriting: Bool = false
    var writeError: String?

    let favoritesStore: FavoritesStore

    var canonicalUUIDForDisplay: String { canonicalUUID(uuid) ?? uuid }

    private let client: HTTPStateClient
    private let defaults: UserDefaults

    private var lifecycle: Task<Void, Never>?
    private var reloadTask: Task<Void, Never>?
    private var writeTask: Task<Void, Never>?

    init(client: HTTPStateClient, favoritesStore: FavoritesStore, defaults: UserDefaults = .standard) {
        self.client = client
        self.favoritesStore = favoritesStore
        self.defaults = defaults
        self.uuid = defaults.string(forKey: Keys.uuid) ?? Self.bootstrapUUID
    }

    convenience init() {
        let client = HTTPStateClient.makeDefault()
        let store = FavoritesStore(client: client, storeUUID: FavoritesStore.bootstrappedStoreUUID())
        self.init(client: client, favoritesStore: store)
    }

    @MainActor deinit {
        lifecycle?.cancel()
        reloadTask?.cancel()
        writeTask?.cancel()
    }

    /// Begin the background lifecycle: load favorites, do an initial reload,
    /// then refresh every 60 seconds. Idempotent — repeated calls are no-ops
    /// while the lifecycle is running. The Task is retained internally; cancel
    /// via `stop()` or by deallocating the view model.
    func start() {
        if let task = lifecycle, !task.isCancelled { return }
        lifecycle = Task { [weak self] in
            await self?.favoritesStore.load()
            await self?.performReload()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    return
                }
                guard let self else { return }
                await self.performReload()
            }
        }
    }

    /// Cancel the background lifecycle. Safe to call from anywhere; idempotent.
    func stop() {
        lifecycle?.cancel()
        lifecycle = nil
    }

    /// Trigger a one-shot reload. Cancels any in-flight reload so a fast
    /// double-tap on the refresh button doesn't fire two requests.
    func reload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            await self?.performReload()
        }
    }

    /// Write the pending value. Cancels any in-flight write.
    func writePending() {
        writeTask?.cancel()
        writeTask = Task { [weak self] in
            await self?.performWrite()
        }
    }

    func selectFavorite(_ favorite: Favorite) {
        uuid = favorite.uuid
        reload()
    }

    func addFavorite(_ favorite: Favorite) {
        Task { [weak self] in
            await self?.favoritesStore.add(favorite)
        }
    }

    func removeFavorites(at offsets: IndexSet) {
        Task { [weak self] in
            await self?.favoritesStore.remove(at: offsets)
        }
    }

    private func performReload() async {
        let target = uuid
        let next: String
        do {
            next = try await client.get(target) ?? "—"
        } catch {
            if Task.isCancelled { return }
            next = "Error"
        }
        guard !Task.isCancelled, target == uuid else { return }
        value = next
        retrievedAt = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func performWrite() async {
        let toWrite = pendingValue
        guard !toWrite.isEmpty, !isWriting else { return }
        isWriting = true
        writeError = nil
        defer { isWriting = false }
        do {
            try await client.set(uuid, toWrite)
        } catch {
            if Task.isCancelled { return }
            writeError = humanReadable(error)
            return
        }
        guard !Task.isCancelled else { return }
        pendingValue = ""
        await performReload()
    }

    private static let bootstrapUUID = "0a3d4b8b161b4817a4f43d239e29cec1"

    private enum Keys {
        static let uuid = "uuid"
    }

    private func humanReadable(_ error: HTTPStateError) -> String {
        switch error {
        case .invalidUUID(let value): "“\(value)” isn't a valid UUID."
        case .transport(let description): "Network error: \(description)"
        case .httpStatus(let code): "Server returned HTTP \(code)."
        case .decodingFailed(let reason): "Couldn't read response: \(reason)"
        case .notConnected: "Not connected."
        }
    }
}

extension HTTPStateClient {
    static func makeDefault() -> HTTPStateClient {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return HTTPStateClient(configuration: HTTPStateConfiguration(
            endpoint: URL(string: "https://httpstate.com")!,
            webSocketEndpoint: URL(string: "wss://httpstate.com")!,
            transport: URLSessionTransport(session: URLSession(configuration: configuration))
        ))
    }
}
