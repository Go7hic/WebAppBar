import SwiftUI

// MARK: - 底部快捷访问栏
struct QuickAccessBar: View {
    @ObservedObject var viewModel: WebViewModel
    @ObservedObject var store: SiteStore
    @Binding var inputText: String
    var onEdit: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if store.sites.isEmpty {
                emptyState
            } else {
                siteButtons
            }

            Divider()
                .frame(height: 28)
                .padding(.horizontal, 2)

            // 编辑按钮
            Button(action: onEdit) {
                VStack(spacing: 2) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .frame(height: 16)
                    Text("编辑")
                        .font(.system(size: 9))
                        .lineLimit(1)
                }
                .frame(width: 44)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.borderless)
            .help("编辑网站")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private var siteButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.sites) { site in
                    let isSelected = viewModel.selectedTab == site.key
                    Button(action: {
                        viewModel.switchTab(to: site.key)
                        inputText = viewModel.webViews[site.key]?.url?.absoluteString ?? site.key
                    }) {
                        VStack(spacing: 2) {
                            SiteFaviconView(site: site, size: 16, cornerRadius: 4)
                                .frame(height: 16)
                            Text(site.name)
                                .font(.system(size: 9))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minWidth: 44)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(site.name)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.dashed")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            Text("暂无网站，点击编辑添加")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

struct SiteFaviconView: View {
    let site: SiteItem
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: site.faviconURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            default:
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
