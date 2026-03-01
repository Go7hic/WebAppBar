import SwiftUI

// MARK: - 应用主入口
// 纯菜单栏应用，无 Dock 图标，点击菜单栏图标弹出 popover 窗口
@main
struct WebAppBarApp: App {
    // 共享的 WebView 状态模型，整个应用生命周期保持
    @StateObject private var viewModel = WebViewModel()

    var body: some Scene {
        // 使用 MenuBarExtra 创建菜单栏图标，点击弹出窗口
        MenuBarExtra("WebAppBar", systemImage: "globe") {
            MainView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window) // 弹出窗口样式（非菜单样式）
    }
}
