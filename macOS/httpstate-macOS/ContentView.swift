import AppKit
import Combine
import SwiftUI
import WidgetKit

class NoSelectTextField: NSTextField {
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        DispatchQueue.main.async {
            if let editor = self.currentEditor() {
                editor.selectedRange = NSRange(location: self.stringValue.count, length: 0)
            }
        }
        return result
    }
}

struct UUIDTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: (() -> Void)?

    func makeNSView(context: Context) -> NoSelectTextField {
        let tf = NoSelectTextField()
        tf.stringValue = text
        tf.isEditable = true
        tf.isBordered = false
        tf.drawsBackground = false
        tf.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        tf.textColor = NSColor.white.withAlphaComponent(0.7)
        tf.cell?.wraps = false
        tf.cell?.isScrollable = true
        tf.delegate = context.coordinator
        tf.focusRingType = .none
        tf.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return tf
    }

    func updateNSView(_ nsView: NoSelectTextField, context: Context) {
        if nsView.stringValue != text && nsView.currentEditor() == nil {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: UUIDTextField
        init(_ parent: UUIDTextField) { self.parent = parent }
        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NoSelectTextField else { return }
            let filtered = tf.stringValue.components(separatedBy: .newlines).joined()
            tf.stringValue = filtered
            parent.text = filtered
        }
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit?()
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

struct ContentView: View {
    @State private var stateData: HTTPStateData = HTTPStateData(value: "—", retrievedAt: Date())
    @AppStorage("uuid") private var uuid: String = "45fb36540e9244daaa21ca409c6bdab3"
    @Environment(\.scenePhase) var scenePhase

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HTTPState")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(0.2)
                        .foregroundStyle(.white)
                    UUIDTextField(text: $uuid, onCommit: reloadData)
                        .frame(height: 20)
                }
                Spacer()
                MascotIcon(size: 52)
            }

            Spacer(minLength: 24)

            Text(stateData.value)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 24)

            HStack {
                Spacer()
                Text("At \(stateData.retrievedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(28)
        .frame(minWidth: 400, minHeight: 280)
        .background(Color(red: 152/255, green: 126/255, blue: 184/255))
        .contentShape(Rectangle())
        .onTapGesture {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onAppear {
            reloadData()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                reloadData()
            }
        }
        .onReceive(timer) { _ in
            reloadData()
        }
    }

    private func reloadData() {
        Task {
            stateData = await HTTPStateService.shared.fetch(uuid: uuid)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
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
                    .padding(3)
            )
    }
}

#Preview {
    ContentView()
}
