import SwiftUI

// MARK: - 主视图
struct MainView: View {
    @ObservedObject var viewModel: WebViewModel
    @ObservedObject var store: SiteStore
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var isEditing: Bool = false

    var body: some View {
        ZStack {
            browserView
            if isEditing {
                SiteEditView(store: store) {
                    isEditing = false
                }
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .frame(width: 420, height: 640)
    }

    private var browserView: some View {
        VStack(spacing: 0) {
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

            // 网页区域 / 空状态
            if store.sites.isEmpty {
                emptyWebArea
            } else {
                WebViewRepresentable(viewModel: viewModel, sites: store.sites)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            QuickAccessBar(
                viewModel: viewModel,
                store: store,
                inputText: $inputText,
                onEdit: { isEditing = true }
            )
        }
        .background(.background)
        .onAppear {
            // 首次出现时同步 selectedTab 为第一个 site
            if viewModel.selectedTab.isEmpty, let first = store.sites.first {
                viewModel.selectedTab = first.key
            }
        }
        .onChange(of: viewModel.currentURL) { _, newURL in
            inputText = newURL
        }
        .onChange(of: viewModel.selectedTab) { _, _ in
            let url = viewModel.currentWebView?.url?.absoluteString ?? ""
            inputText = url
        }
        .onChange(of: store.sites) { _, newSites in
            viewModel.handleSitesChanged(newSites: newSites)
        }
    }

    private var emptyWebArea: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "globe.slash")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("没有网站")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("点击底部「编辑」按钮添加你常用的网站")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { isEditing = true }) {
                Label("去添加", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
