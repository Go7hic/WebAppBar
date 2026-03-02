import SwiftUI
import WebKit
import Combine

// MARK: - WebView 状态管理
final class WebViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentURL: String = ""
    @Published var pageTitle: String = ""
    @Published var estimatedProgress: Double = 0
    @Published var history: [HistoryItem] = []

    // 当前选中的 tab key
    @Published var selectedTab: String = ""

    // 所有 tab 的 WKWebView 实例，由 WebViewRepresentable 注入
    var webViews: [String: WKWebView] = [:]

    // 已完成首次加载的 tab，避免重复 load 初始 URL
    var loadedTabs: Set<String> = []

    var currentWebView: WKWebView? { webViews[selectedTab] }

    func switchTab(to key: String) {
        guard key != selectedTab else { return }
        selectedTab = key
        syncActiveTabState()
    }

    /// 将当前活跃 WebView 的状态同步到 published properties
    func syncActiveTabState() {
        guard let wv = currentWebView else { return }
        DispatchQueue.main.async {
            self.isLoading = wv.isLoading
            self.canGoBack = wv.canGoBack
            self.canGoForward = wv.canGoForward
            self.currentURL = wv.url?.absoluteString ?? ""
            self.pageTitle = wv.title ?? ""
            self.estimatedProgress = wv.estimatedProgress
        }
    }

    func loadURL(_ input: String) {
        let resolved = ShortcutManager.shared.resolve(input)
        guard let url = URL(string: resolved) else { return }
        currentWebView?.load(URLRequest(url: url))
    }

    func goBack() { currentWebView?.goBack() }
    func goForward() { currentWebView?.goForward() }
    func reload() { currentWebView?.reload() }
    func stopLoading() { currentWebView?.stopLoading() }

    func addHistory(title: String, url: String) {
        guard !url.isEmpty else { return }
        let item = HistoryItem(title: title.isEmpty ? url : title, url: url)
        history.removeAll { $0.url == url }
        history.insert(item, at: 0)
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
    }

    // MARK: - 动态 tab 管理

    /// 删除 WebView 及对应状态，由 WebViewRepresentable 调用
    func removeWebView(forKey key: String) {
        webViews.removeValue(forKey: key)
        loadedTabs.remove(key)
    }

    /// sites 列表变更时调用：若当前 tab 被删除，切换到第一个可用 tab
    func handleSitesChanged(newSites: [SiteItem]) {
        let newKeys = Set(newSites.map(\.key))
        // 清理已不存在的 loadedTabs 记录
        loadedTabs = loadedTabs.intersection(newKeys)

        if newKeys.contains(selectedTab) { return }

        // 当前 tab 已被删除
        if let first = newSites.first {
            switchTab(to: first.key)
        } else {
            selectedTab = ""
            isLoading = false
            canGoBack = false
            canGoForward = false
            currentURL = ""
            pageTitle = ""
            estimatedProgress = 0
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
