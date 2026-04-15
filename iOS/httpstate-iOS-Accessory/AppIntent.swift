import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your httpstate widget." }

    @Parameter(title: "Title", default: "HTTPState")
    var title: String

    @Parameter(title: "UUID", default: "45fb36540e9244daaa21ca409c6bdab3")
    var uuid: String
}
