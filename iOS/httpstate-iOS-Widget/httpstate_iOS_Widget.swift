// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), stateData: HTTPStateData(value: "—", retrievedAt: Date()))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if context.isPreview {
            return SimpleEntry(date: Date(), configuration: configuration, stateData: HTTPStateData(value: "1775863208646", retrievedAt: Date()))
        }
        let data = await HTTPStateService.shared.fetch(uuid: configuration.uuid)
        return SimpleEntry(date: Date(), configuration: configuration, stateData: data)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let data = await HTTPStateService.shared.fetch(uuid: configuration.uuid)
        let entry = SimpleEntry(date: Date(), configuration: configuration, stateData: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let stateData: HTTPStateData
}

struct MascotIcon: View {
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .overlay(
                Image("Mascot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .padding(2)
            )
    }
}

struct httpstate_iOS_WidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.configuration.title)
                        .font(.system(size: 14, weight: .bold))
                        .tracking(0.1)
                        .foregroundStyle(.white)
                    Text(entry.configuration.uuid)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                MascotIcon(size: 22)
            }

            Spacer(minLength: 8)

            Text(entry.stateData.value)
                .font(.system(size: 22, weight: .bold))
                .tracking(0.1)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 6)

            HStack {
                Spacer()
                Text("At \(entry.stateData.retrievedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(4)
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.configuration.title)
                        .font(.system(size: 14, weight: .bold))
                        .tracking(0.1)
                        .foregroundStyle(.white)
                    Text(entry.configuration.uuid)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                MascotIcon(size: 28)
            }

            Spacer(minLength: 12)

            Text(entry.stateData.value)
                .font(.system(size: 28, weight: .bold))
                .tracking(0.1)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 8)

            HStack {
                Spacer()
                Text("At \(entry.stateData.retrievedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(4)
    }
}

struct httpstate_iOS_Widget: Widget {
    let kind: String = "httpstate_iOS_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            httpstate_iOS_WidgetEntryView(entry: entry)
                .containerBackground(entry.configuration.color.color, for: .widget)
        }
        .configurationDisplayName("HTTPState")
        .description("httpstate.com")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
