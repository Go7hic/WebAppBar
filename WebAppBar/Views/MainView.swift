import SwiftUI

// MARK: - 主视图
// 包含导航栏、进度条、WebView、快捷按钮四个区域
struct MainView: View {
    @ObservedObject var viewModel: WebViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏（后退/前进/刷新 + URL 输入框 + Go 按钮）
            NavigationBar(
                viewModel: viewModel,
                inputText: $inputText,
                isInputFocused: $isInputFocused
            )

            // 加载进度条
            ZStack(alignment: .leading) {
                if viewModel.isLoading {
                    ProgressView(value: viewModel.estimatedProgress)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                }
            }
            .frame(height: viewModel.isLoading ? 2 : 0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)

            // 网页区域
            WebViewRepresentable(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 底部快捷访问栏
            QuickAccessBar(viewModel: viewModel, inputText: $inputText)
        }
        // 窗口尺寸：宽 420pt，高 640pt
        .frame(width: 420, height: 640)
        .background(.background)
        .onAppear {
            // 弹出时自动聚焦输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        // 监听当前 URL 变化，同步到输入框
        .onChange(of: viewModel.currentURL) { _, newURL in
            inputText = newURL
        }
    }
}
