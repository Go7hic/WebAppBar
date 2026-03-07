import SwiftUI
import AppKit

// MARK: - AppDelegate: context menu
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self else { return event }
            if self.isStatusBarEvent(event) {
                self.showContextMenu(for: event)
                return nil
            }
            return event
        }
    }

    private func isStatusBarEvent(_ event: NSEvent) -> Bool {
        guard let window = event.window else { return false }
        // MenuBarExtra window class name contains "StatusBar"
        return NSStringFromClass(type(of: window)).contains("StatusBar")
    }

    private func showContextMenu(for event: NSEvent) {
        let menu = NSMenu()
        let quit = NSMenuItem(
            title: "Quit WebAppBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.keyEquivalentModifierMask = .command
        menu.addItem(quit)
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

// MARK: - App entry
@main
struct WebAppBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = WebViewModel()
    @StateObject private var siteStore = SiteStore()
    @State private var isMenuBarExtraInserted = true
    
    private static let menuBarIconImage: NSImage? = {
        guard let original = NSImage(named: "MenuBarIcon") else { return nil }
        let targetSize = NSSize(width: 16, height: 16)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        original.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: original.size),
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()
        return resized
    }()

    var body: some Scene {
        MenuBarExtra(isInserted: $isMenuBarExtraInserted) {
            MainView(
                viewModel: viewModel,
                store: siteStore
            )
        } label: {
            if let icon = Self.menuBarIconImage {
                Image(nsImage: icon)
                    .interpolation(.high)
                    .antialiased(true)
            } else {
                Image(systemName: "globe")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
