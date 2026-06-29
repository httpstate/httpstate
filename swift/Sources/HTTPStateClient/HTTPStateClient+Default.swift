// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026

@_exported import HTTPState
@_exported import HTTPStateTransportURLSession

extension HTTPStateConfiguration {
    /// The expected default for most consumers: `httpstate.com` over
    /// URLSession. Explicit, so code that constructs a client still reads as
    /// a deliberate wiring choice rather than magic.
    public static var `default`: HTTPStateConfiguration { .httpstateDotCom }
}
