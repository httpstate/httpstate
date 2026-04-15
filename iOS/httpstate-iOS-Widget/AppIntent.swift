// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import AppIntents
import SwiftUI
import WidgetKit

enum WidgetColor: String, AppEnum {
    case graphite
    case lavender
    case lemon
    case mint
    case peach
    case rose
    case ruby
    case sage
    case sky
    case walnut

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Color" }
    static var caseDisplayRepresentations: [WidgetColor: DisplayRepresentation] = [
        .graphite: "Graphite",
        .lavender: "Lavender",
        .lemon: "Lemon",
        .mint: "Mint",
        .peach: "Peach",
        .rose: "Rose",
        .ruby: "Ruby",
        .sage: "Sage",
        .sky: "Sky",
        .walnut: "Walnut",
    ]

    var color: Color {
        switch self {
        case .graphite: Color(red: 58/255, green: 60/255, blue: 78/255)
        case .lavender: Color(red: 152/255, green: 126/255, blue: 184/255)
        case .lemon: Color(red: 220/255, green: 196/255, blue: 36/255)
        case .mint: Color(red: 72/255, green: 176/255, blue: 88/255)
        case .peach: Color(red: 224/255, green: 138/255, blue: 88/255)
        case .rose: Color(red: 208/255, green: 116/255, blue: 148/255)
        case .ruby: Color(red: 200/255, green: 56/255, blue: 72/255)
        case .sage: Color(red: 148/255, green: 162/255, blue: 112/255)
        case .sky: Color(red: 108/255, green: 150/255, blue: 208/255)
        case .walnut: Color(red: 118/255, green: 86/255, blue: 50/255)
        }
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your httpstate widget." }

    @Parameter(title: "Color", default: .lavender)
    var color: WidgetColor

    @Parameter(title: "Title", default: "HTTPState")
    var title: String

    @Parameter(title: "UUID", default: "45fb36540e9244daaa21ca409c6bdab3")
    var uuid: String
}
