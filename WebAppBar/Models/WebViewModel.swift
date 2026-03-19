import SwiftUI
import WebKit
import Combine

// MARK: - WebView state
final class WebViewModel: ObservableObject {
    private let retentionPolicy = WebViewRetentionPolicy(maxRetainedTabs: 3)

    @Published var urlString: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentURL: String = ""
    @Published var pageTitle: String = ""
    @Published var estimatedProgress: Double = 0
    @Published var history: [HistoryItem] = []

    // Selected tab key
    @Published var selectedTab: String = ""

    // WKWebView per tab, injected by WebViewRepresentable
    var webViews: [String: WKWebView] = [:]

    // Tabs that have loaded once (avoid reloading initial URL)
    var loadedTabs: Set<String> = []
    private(set) var recentlySelectedTabs: [String] = []

    var currentWebView: WKWebView? { webViews[selectedTab] }

    func switchTab(to key: String) {
        guard key != selectedTab else { return }
        selectedTab = key
        markTabRecentlyUsed(key)
        syncActiveTabState()
    }

    /// Sync active WebView state to published properties
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

    // MARK: - Dynamic tab management

    /// Remove WebView and state; called by WebViewRepresentable
    func removeWebView(forKey key: String) {
        webViews.removeValue(forKey: key)
        loadedTabs.remove(key)
    }

    func retainedWebViewKeys(for sites: [SiteItem]) -> Set<String> {
        retentionPolicy.retainedKeys(
            selectedKey: selectedTab,
            recentlySelectedKeys: recentlySelectedTabs,
            availableKeys: Set(sites.map(\.key))
        )
    }

    /// Called when sites change; if current tab removed, switch to first
    func handleSitesChanged(newSites: [SiteItem]) {
        let newKeys = Set(newSites.map(\.key))
        // Prune loadedTabs for removed sites
        loadedTabs = loadedTabs.intersection(newKeys)
        recentlySelectedTabs = recentlySelectedTabs.filter { newKeys.contains($0) }

        if newKeys.contains(selectedTab) { return }

        // Current tab was removed
        if let first = newSites.first {
            switchTab(to: first.key)
        } else {
            selectedTab = ""
            recentlySelectedTabs.removeAll()
            isLoading = false
            canGoBack = false
            canGoForward = false
            currentURL = ""
            pageTitle = ""
            estimatedProgress = 0
        }
    }

    func ensureSelectedTabIsTracked() {
        guard !selectedTab.isEmpty else { return }
        markTabRecentlyUsed(selectedTab)
    }

    private func markTabRecentlyUsed(_ key: String) {
        guard !key.isEmpty else { return }
        recentlySelectedTabs.removeAll { $0 == key }
        recentlySelectedTabs.insert(key, at: 0)
    }
}

// MARK: - History item
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

struct WebViewRetentionPolicy {
    let maxRetainedTabs: Int

    func retainedKeys(
        selectedKey: String,
        recentlySelectedKeys: [String],
        availableKeys: Set<String>
    ) -> Set<String> {
        guard !selectedKey.isEmpty else { return [] }

        let orderedKeys = [selectedKey] + recentlySelectedKeys.filter { $0 != selectedKey }
        let filteredKeys = orderedKeys.filter { availableKeys.contains($0) }
        return Set(filteredKeys.prefix(maxRetainedTabs))
    }
}
