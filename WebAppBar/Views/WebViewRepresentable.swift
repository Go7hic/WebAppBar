import SwiftUI
import WebKit

// MARK: - 多 WebView 容器
struct WebViewRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    let sites: [SiteItem]

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true

        for site in sites {
            addWebView(for: site, to: container, coordinator: context.coordinator)
        }

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let currentKeys = Set(viewModel.webViews.keys)
        let newKeys = Set(sites.map(\.key))

        // 删除已移除的 WebView
        for key in currentKeys.subtracting(newKeys) {
            if let wv = viewModel.webViews[key] {
                wv.removeFromSuperview()
                context.coordinator.removeObservations(for: key)
                viewModel.removeWebView(forKey: key)
            }
        }

        // 添加新增的 WebView
        for site in sites where !currentKeys.contains(site.key) {
            addWebView(for: site, to: nsView, coordinator: context.coordinator)
        }

        // 更新可见性
        let selected = viewModel.selectedTab
        for (key, wv) in viewModel.webViews {
            let shouldShow = key == selected
            if wv.isHidden == shouldShow {
                wv.isHidden = !shouldShow
            }
            if shouldShow && !viewModel.loadedTabs.contains(key) {
                if let site = sites.first(where: { $0.key == key }) {
                    if let url = URL(string: site.url) {
                        wv.load(URLRequest(url: url))
                        viewModel.loadedTabs.insert(key)
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func addWebView(for site: SiteItem, to container: NSView, coordinator: Coordinator) {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isHidden = (site.key != viewModel.selectedTab)

        container.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        viewModel.webViews[site.key] = webView
        coordinator.observe(webView, key: site.key)

        // 预加载选中 tab，其余懒加载
        if site.key == viewModel.selectedTab {
            if let url = URL(string: site.url) {
                webView.load(URLRequest(url: url))
                viewModel.loadedTabs.insert(site.key)
            }
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var viewModel: WebViewModel
        private var observations: [String: [NSKeyValueObservation]] = [:]

        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
        }

        func observe(_ webView: WKWebView, key: String) {
            let obs: [NSKeyValueObservation] = [
                webView.observe(\.isLoading, options: .new) { [weak self] wv, _ in
                    guard let self, self.viewModel.selectedTab == key else { return }
                    DispatchQueue.main.async { self.viewModel.isLoading = wv.isLoading }
                },
                webView.observe(\.canGoBack, options: .new) { [weak self] wv, _ in
                    guard let self, self.viewModel.selectedTab == key else { return }
                    DispatchQueue.main.async { self.viewModel.canGoBack = wv.canGoBack }
                },
                webView.observe(\.canGoForward, options: .new) { [weak self] wv, _ in
                    guard let self, self.viewModel.selectedTab == key else { return }
                    DispatchQueue.main.async { self.viewModel.canGoForward = wv.canGoForward }
                },
                webView.observe(\.url, options: .new) { [weak self] wv, _ in
                    guard let self, self.viewModel.selectedTab == key else { return }
                    DispatchQueue.main.async {
                        self.viewModel.currentURL = wv.url?.absoluteString ?? ""
                    }
                },
                webView.observe(\.title, options: .new) { [weak self] wv, _ in
                    guard let self, self.viewModel.selectedTab == key else { return }
                    DispatchQueue.main.async { self.viewModel.pageTitle = wv.title ?? "" }
                },
                webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                    guard let self, self.viewModel.selectedTab == key else { return }
                    DispatchQueue.main.async { self.viewModel.estimatedProgress = wv.estimatedProgress }
                },
            ]
            observations[key] = obs
        }

        func removeObservations(for key: String) {
            observations.removeValue(forKey: key)
        }

        // MARK: - WKNavigationDelegate

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let title = webView.title ?? ""
            let url = webView.url?.absoluteString ?? ""
            viewModel.addHistory(title: title, url: url)
        }

        // MARK: - WKUIDelegate

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
            completionHandler()
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.addButton(withTitle: "取消")
            let response = alert.runModal()
            completionHandler(response == .alertFirstButtonReturn)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = NSAlert()
            alert.messageText = prompt
            alert.alertStyle = .informational
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
            textField.stringValue = defaultText ?? ""
            alert.accessoryView = textField
            alert.addButton(withTitle: "确定")
            alert.addButton(withTitle: "取消")
            let response = alert.runModal()
            completionHandler(response == .alertFirstButtonReturn ? textField.stringValue : nil)
        }
    }
}
