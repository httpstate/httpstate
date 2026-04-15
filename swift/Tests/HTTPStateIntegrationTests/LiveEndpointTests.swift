// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

import Foundation
import Testing
import HTTPStateClient

// Integration tests hit the real httpstate.com service. They are gated
// behind the HTTPSTATE_INTEGRATION=1 env var so `swift test` stays hermetic
// for anyone running it without deliberate intent.
//
// Real tests land after the skeleton clears cross-ref. Planned coverage:
// - round-trip a fresh uuid through set/get
// - live change emission via changes(for:) with a second client writing
// - case sensitivity probe: dashed vs undashed, upper vs lower
// - reconnect behavior after a forced disconnect

private var integrationEnabled: Bool {
    ProcessInfo.processInfo.environment["HTTPSTATE_INTEGRATION"] == "1"
}

@Test(.enabled(if: integrationEnabled))
func placeholder() {
    #expect(Bool(true))
}
