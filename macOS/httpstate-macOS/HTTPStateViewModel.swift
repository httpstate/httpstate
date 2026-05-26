import AppKit
import Combine
import SwiftUI
import WidgetKit

class HTTPStateViewModel: ObservableObject {
    @Published var stateData = HTTPStateData(value: "—", retrievedAt: Date()) {
        didSet { WidgetCenter.shared.reloadAllTimelines() }
    }
    @Published var title = UserDefaults.standard.string(forKey: "title") ?? "HTTPState" {
        didSet { UserDefaults.standard.set(title, forKey: "title") }
    }
    @Published var uuid = UserDefaults.standard.string(forKey: "uuid") ?? "45fb36540e9244daaa21ca409c6bdab3" {
        didSet { UserDefaults.standard.set(uuid, forKey: "uuid") }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &cancellables)
    }

    func reloadData() {
        Task { @MainActor in
            stateData = await HTTPStateService.shared.fetch(uuid: uuid)
        }
    }
}
