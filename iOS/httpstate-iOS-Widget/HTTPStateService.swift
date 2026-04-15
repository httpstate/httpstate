// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import Foundation

struct HTTPStateService {
    static let shared = HTTPStateService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    func fetch(uuid: String) async -> HTTPStateData {
        guard let endpointURL = URL(string: "https://httpstate.com/\(uuid)") else {
            return HTTPStateData(value: "Error", retrievedAt: Date())
        }
        do {
            let (data, _) = try await session.data(from: endpointURL)
            let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "—"
            return HTTPStateData(value: value, retrievedAt: Date())
        } catch {
            return HTTPStateData(value: "Error", retrievedAt: Date())
        }
    }
}