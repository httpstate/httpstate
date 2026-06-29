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

/// Persists the user's favorites list to httpstate.com itself, dogfooding the
/// API the app exists to demonstrate. A per-install UUID is generated on
/// first launch and held in UserDefaults; the favorites array is JSON-
/// encoded and round-tripped through `client.get/set` against that UUID.
///
/// Local UserDefaults caches the most recent successful read so the UI has
/// something to show before the network round-trip completes. Offline
/// mutations are best-effort: a subsequent `load()` from a still-stale remote
/// can overwrite an offline change. Acceptable for v1.
@MainActor
@Observable
final class FavoritesStore {
    private(set) var favorites: [Favorite] = []

    let storeUUID: String

    private let client: HTTPStateClient
    private let cache: UserDefaults

    init(client: HTTPStateClient, storeUUID: String, cache: UserDefaults = .standard) {
        self.client = client
        self.storeUUID = storeUUID
        self.cache = cache
        if let data = cache.data(forKey: Keys.cache),
           let decoded = try? JSONDecoder().decode([Favorite].self, from: data) {
            self.favorites = decoded
        }
    }

    func load() async {
        do {
            guard let raw = try await client.get(storeUUID),
                  let data = raw.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([Favorite].self, from: data) else {
                return
            }
            favorites = decoded
            cacheLocally(decoded)
        } catch {
            // Offline or transport error — keep the local cache.
        }
    }

    func add(_ favorite: Favorite) async {
        var next = favorites
        next.append(favorite)
        await commit(next)
    }

    func remove(at offsets: IndexSet) async {
        var next = favorites
        for index in offsets {
            next.remove(at: index)
        }
        await commit(next)
    }

    private func commit(_ next: [Favorite]) async {
        favorites = next
        cacheLocally(next)
        guard let data = try? JSONEncoder().encode(next),
              let json = String(data: data, encoding: .utf8) else { return }
        try? await client.set(storeUUID, json)
    }

    private func cacheLocally(_ list: [Favorite]) {
        if let encoded = try? JSONEncoder().encode(list) {
            cache.set(encoded, forKey: Keys.cache)
        }
    }

    private enum Keys {
        static let cache = "favorites_cache_v1"
    }
}

extension FavoritesStore {
    /// Resolve the per-install UUID that namespaces this store on
    /// httpstate.com. Generated on first call and persisted forever.
    static func bootstrappedStoreUUID(in defaults: UserDefaults = .standard) -> String {
        let key = "favorites_store_uuid"
        if let existing = defaults.string(forKey: key) {
            return existing
        }
        let fresh = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
        defaults.set(fresh, forKey: key)
        return fresh
    }
}
