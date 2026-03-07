import SwiftUI
import WebKit
import AppKit

// MARK: - Multi WebView container
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

        // Remove WebViews for removed sites
        for key in currentKeys.subtracting(newKeys) {
            if let wv = viewModel.webViews[key] {
                wv.removeFromSuperview()
                context.coordinator.removeObservations(for: key)
                viewModel.removeWebView(forKey: key)
            }
        }

        // Add WebViews for new sites
        for site in sites where !currentKeys.contains(site.key) {
            addWebView(for: site, to: nsView, coordinator: context.coordinator)
        }

        // Update visibility
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
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
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

        // Preload selected tab, lazy load others
        if site.key == viewModel.selectedTab {
            if let url = URL(string: site.url) {
                webView.load(URLRequest(url: url))
                viewModel.loadedTabs.insert(site.key)
            }
        }
    }

    // MARK: - Popup delegate（站点用 window.open 开的登录弹窗，独立 delegate 减少关窗崩溃）
    private class PopupDelegate: NSObject, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {
        weak var window: NSWindow?
        var onClose: ((NSWindow, WKWebView?) -> Void)?

        init(window: NSWindow) {
            self.window = window
            super.init()
        }

        /// 页面调 window.close() 时（如登录成功）关掉弹窗
        func webViewDidClose(_ webView: WKWebView) {
            window?.close()
        }

        func windowWillClose(_ notification: Notification) {
            guard let win = notification.object as? NSWindow else { return }
            win.parent?.removeChildWindow(win)
            let webView = win.contentView as? WKWebView
            win.contentView = nil
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
            let callback = onClose
            onClose = nil
            DispatchQueue.main.async { callback?(win, webView) }
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            completionHandler()
        }
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            completionHandler(alert.runModal() == .alertFirstButtonReturn)
        }
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            let alert = NSAlert()
            alert.messageText = prompt
            alert.alertStyle = .informational
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
            textField.stringValue = defaultText ?? ""
            alert.accessoryView = textField
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            completionHandler(alert.runModal() == .alertFirstButtonReturn ? textField.stringValue : nil)
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var viewModel: WebViewModel
        private var observations: [String: [NSKeyValueObservation]] = [:]
        private var popupByWindow: [ObjectIdentifier: PopupDelegate] = [:]
        private var pendingReleasePopupWebViews: [WKWebView] = []

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

        /// 标准弹窗：返回 WKWebView 让 WebKit 往里加载，页面才能正常显示（return nil 会白屏）。
        /// 关窗时用 windowWillClose 里「先移出 webview、延迟释放」尽量减轻崩溃。
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil else { return nil }

            // 已有可见弹窗时复用该窗口：换上新 WKWebView 并返回，让 WebKit 往这个新 webview 加载本次请求，避免多窗口
            for (_, delegate) in popupByWindow {
                if let w = delegate.window, w.isVisible,
                   let oldWv = w.contentView as? WKWebView {
                    pendingReleasePopupWebViews.append(oldWv)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.pendingReleasePopupWebViews.removeAll { $0 === oldWv }
                    }
                    let newWv = WKWebView(frame: .zero, configuration: configuration)
                    newWv.customUserAgent = webView.customUserAgent
                    newWv.allowsBackForwardNavigationGestures = true
                    newWv.translatesAutoresizingMaskIntoConstraints = false
                    newWv.navigationDelegate = delegate
                    newWv.uiDelegate = delegate
                    w.contentView = newWv
                    return newWv
                }
            }

            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            let popupWebView = WKWebView(frame: .zero, configuration: configuration)
            popupWebView.customUserAgent = webView.customUserAgent
            popupWebView.allowsBackForwardNavigationGestures = true
            popupWebView.translatesAutoresizingMaskIntoConstraints = false

            // 文档建议 Menubar App 用 NSPanel 作为弹窗，焦点/隐藏行为更稳定
            let popupPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 740),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            popupPanel.title = "Login"
            popupPanel.center()
            popupPanel.contentView = popupWebView
            if let parentWindow = NSApp.keyWindow {
                parentWindow.addChildWindow(popupPanel, ordered: .above)
            }
            popupPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            let popupDelegate = PopupDelegate(window: popupPanel)
            popupDelegate.onClose = { [weak self] win, wv in
                self?.removePopup(window: win, webview: wv)
            }
            popupPanel.delegate = popupDelegate
            popupWebView.navigationDelegate = popupDelegate
            popupWebView.uiDelegate = popupDelegate

            popupByWindow[ObjectIdentifier(popupPanel)] = popupDelegate
            return popupWebView
        }

        private func removePopup(window: NSWindow, webview: WKWebView?) {
            popupByWindow.removeValue(forKey: ObjectIdentifier(window))
            guard let wv = webview else { return }
            pendingReleasePopupWebViews.append(wv)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.pendingReleasePopupWebViews.removeAll { $0 === wv }
            }
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
            alert.addButton(withTitle: "OK")
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
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
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
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            completionHandler(response == .alertFirstButtonReturn ? textField.stringValue : nil)
        }
    }
}
