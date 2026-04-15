import WidgetKit
import SwiftUI

struct AccessoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AccessoryEntry {
        AccessoryEntry(date: Date(), configuration: ConfigurationAppIntent(), stateData: HTTPStateData(value: "—", retrievedAt: Date()))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> AccessoryEntry {
        if context.isPreview {
            return AccessoryEntry(date: Date(), configuration: configuration, stateData: HTTPStateData(value: "1775863208646", retrievedAt: Date()))
        }
        let data = await HTTPStateService.shared.fetch(uuid: configuration.uuid)
        return AccessoryEntry(date: Date(), configuration: configuration, stateData: data)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<AccessoryEntry> {
        let data = await HTTPStateService.shared.fetch(uuid: configuration.uuid)
        let entry = AccessoryEntry(date: Date(), configuration: configuration, stateData: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct AccessoryEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let stateData: HTTPStateData
}

struct httpstate_iOS_AccessoryEntryView: View {
    var entry: AccessoryProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.stateData.value)
        case .accessoryCircular:
            Text(entry.stateData.value)
                .font(.system(size: 34, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.configuration.title)
                    .font(.system(size: 12, weight: .bold))
                Text(entry.stateData.value)
                    .font(.system(size: 28, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text(entry.stateData.value)
        }
    }
}

struct httpstate_iOS_Accessory: Widget {
    let kind: String = "httpstate_iOS_Accessory"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: AccessoryProvider()) { entry in
            httpstate_iOS_AccessoryEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("HTTPState")
        .description("httpstate.com")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
