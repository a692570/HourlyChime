import Cocoa
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: ChimeSettings

    init(settings: ChimeSettings) {
        self.settings = settings
    }

    func show() {
        if window == nil {
            let viewModel = SettingsViewModel(settings: settings)
            let contentView = SettingsView(viewModel: viewModel, settings: settings)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 180),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Hourly Chime"
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.isReleasedWhenClosed = false
            self.window = window
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
