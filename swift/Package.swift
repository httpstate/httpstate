// swift-tools-version:6.1
// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import PackageDescription

let package = Package(
    name: "HTTPState",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        // Core: protocols, actor, errors, types. No concrete transport.
        // Builds without URLSession so a server/Linux backend can be swapped in.
        .library(name: "HTTPState", targets: ["HTTPState"]),

        // Default transport built on Foundation's URLSession. Darwin-first.
        // Pulled in automatically by the umbrella `HTTPStateClient` product below,
        // or can be depended on directly when composing a custom client.
        .library(name: "HTTPStateTransportURLSession", targets: ["HTTPStateTransportURLSession"]),

        // Umbrella: core + default URLSession transport. What most consumers want.
        .library(name: "HTTPStateClient", targets: ["HTTPStateClient"])
    ],
    targets: [
        .target(
            name: "HTTPState",
            path: "Sources/HTTPState"
        ),
        .target(
            name: "HTTPStateTransportURLSession",
            dependencies: ["HTTPState"],
            path: "Sources/HTTPStateTransportURLSession"
        ),
        .target(
            name: "HTTPStateClient",
            dependencies: ["HTTPState", "HTTPStateTransportURLSession"],
            path: "Sources/HTTPStateClient"
        ),

        // Unit tests run against a mock transport. Fast, hermetic, no network.
        .testTarget(
            name: "HTTPStateTests",
            dependencies: ["HTTPState"],
            path: "Tests/HTTPStateTests"
        ),

        // Integration tests hit the live httpstate.com endpoint.
        // Gated by env var `HTTPSTATE_INTEGRATION=1` so `swift test` stays hermetic by default.
        .testTarget(
            name: "HTTPStateIntegrationTests",
            dependencies: ["HTTPStateClient"],
            path: "Tests/HTTPStateIntegrationTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
