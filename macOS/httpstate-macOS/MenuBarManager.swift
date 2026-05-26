import AppKit
import SwiftUI

class MenuBarManager: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let viewModel: HTTPStateViewModel
    private var hostingView: NSHostingView<MenuBarContent>?

    init(viewModel: HTTPStateViewModel) {
        self.viewModel = viewModel
        super.init()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🐙"
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.minimumWidth = 180
        statusItem.menu = menu

        let content = MenuBarContent(viewModel: viewModel)
        hostingView = NSHostingView(rootView: content)
        hostingView?.frame.size = hostingView?.fittingSize ?? NSSize(width: 180, height: 40)

        let item = NSMenuItem()
        item.view = hostingView
        menu.addItem(item)
    }

    func menuWillOpen(_ menu: NSMenu) {
        hostingView?.frame.size = hostingView?.fittingSize ?? NSSize(width: 180, height: 40)
        viewModel.reloadData()
    }
}

struct MenuBarContent: View {
    @ObservedObject var viewModel: HTTPStateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.title)
                .font(.headline)
            Text(viewModel.stateData.value)
                .font(.body)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
