import SwiftUI
import WebKit

// MARK: - WKWebView 桥接到 SwiftUI
// 使用 NSViewRepresentable 将 WKWebView 嵌入 SwiftUI 视图层级
struct WebViewRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // 允许 JavaScript
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // 模拟 iPhone User-Agent，让网站返回移动端布局
        webView.customUserAgent = """
            Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) \
            AppleWebKit/605.1.15 (KHTML, like Gecko) \
            Version/17.5 Mobile/15E148 Safari/604.1
            """

        // 允许左右滑动手势进行前进/后退导航
        webView.allowsBackForwardNavigationGestures = true

        // 设置 KVO 观察
        context.coordinator.observe(webView)

        // 将 webView 引用存入 viewModel，供外部控制
        viewModel.webView = webView

        // 默认加载 ChatGPT
        if let url = URL(string: "https://chatgpt.com") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 状态由 viewModel 驱动，此处无需额外更新
    }

    // MARK: - Coordinator
    // 桥接 WKNavigationDelegate / WKUIDelegate，并通过 KVO 同步状态
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var viewModel: WebViewModel
        private var observations: [NSKeyValueObservation] = []

        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
        }

        /// 订阅 WKWebView 的关键属性变化，实时同步到 viewModel
        func observe(_ webView: WKWebView) {
            observations = [
                webView.observe(\.isLoading, options: .new) { [weak self] wv, _ in
                    DispatchQueue.main.async {
                        self?.viewModel.isLoading = wv.isLoading
                    }
                },
                webView.observe(\.canGoBack, options: .new) { [weak self] wv, _ in
                    DispatchQueue.main.async {
                        self?.viewModel.canGoBack = wv.canGoBack
                    }
                },
                webView.observe(\.canGoForward, options: .new) { [weak self] wv, _ in
                    DispatchQueue.main.async {
                        self?.viewModel.canGoForward = wv.canGoForward
                    }
                },
                webView.observe(\.url, options: .new) { [weak self] wv, _ in
                    DispatchQueue.main.async {
                        self?.viewModel.currentURL = wv.url?.absoluteString ?? ""
                    }
                },
                webView.observe(\.title, options: .new) { [weak self] wv, _ in
                    DispatchQueue.main.async {
                        let title = wv.title ?? ""
                        self?.viewModel.pageTitle = title
                    }
                },
                webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                    DispatchQueue.main.async {
                        self?.viewModel.estimatedProgress = wv.estimatedProgress
                    }
                },
            ]
        }

        // MARK: - WKNavigationDelegate

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // 允许所有导航请求，在当前 WebView 内加载
            decisionHandler(.allow)
        }

        /// 页面加载完成后，记录到历史
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let title = webView.title ?? ""
            let url = webView.url?.absoluteString ?? ""
            viewModel.addHistory(title: title, url: url)
        }

        // MARK: - WKUIDelegate

        /// 处理 window.open()：在当前 WebView 内加载，不弹出新窗口
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

        /// 处理 JavaScript alert()
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

        /// 处理 JavaScript confirm()
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

        /// 处理 JavaScript prompt()
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
