// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import Foundation

struct Favorite: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var uuid: String
    var addedAt: Date = Date()
}

/// Validate and normalize a uuid string for UI input. Mirrors the canonical
/// form the swift package uses internally (32-char no-dash lowercase hex)
/// without exposing it publicly across the package boundary.
func canonicalUUID(_ string: String) -> String? {
    let stripped = string
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "-", with: "")
        .lowercased()
    guard stripped.count == 32, stripped.allSatisfy(\.isHexDigit) else {
        return nil
    }
    return stripped
}
