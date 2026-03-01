import SwiftUI
import WebKit
import Combine

// MARK: - WebView 状态管理
// 负责 WebView 的所有状态跟踪和操作指令
final class WebViewModel: ObservableObject {
    // 地址栏当前显示的文本
    @Published var urlString: String = ""
    // 网页加载状态
    @Published var isLoading: Bool = false
    // 导航能力
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    // 当前 URL 和页面标题
    @Published var currentURL: String = ""
    @Published var pageTitle: String = ""
    // 加载进度 0.0 ~ 1.0
    @Published var estimatedProgress: Double = 0
    // 历史记录（最近访问）
    @Published var history: [HistoryItem] = []

    // 对 WKWebView 的弱引用，由 NSViewRepresentable 设置
    weak var webView: WKWebView?

    // 加载 URL（通过 ShortcutManager 解析输入）
    func loadURL(_ input: String) {
        let resolved = ShortcutManager.shared.resolve(input)
        guard let url = URL(string: resolved) else { return }
        webView?.load(URLRequest(url: url))
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }
    func stopLoading() { webView?.stopLoading() }

    // 添加历史记录
    func addHistory(title: String, url: String) {
        guard !url.isEmpty else { return }
        let item = HistoryItem(title: title.isEmpty ? url : title, url: url)
        // 去重：移除相同 URL 的旧记录
        history.removeAll { $0.url == url }
        history.insert(item, at: 0)
        // 保留最近 50 条
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
    }
}

// MARK: - 历史记录条目
struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let date: Date

    init(title: String, url: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.date = Date()
    }
}
