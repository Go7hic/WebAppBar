import SwiftUI

struct SiteEditView: View {
    @ObservedObject var store: SiteStore
    var onDismiss: () -> Void

    @State private var editingItem: SiteItem?
    @State private var showingAdd = false
    @State private var showingDeleteAllAlert = false
    @State private var pendingDeleteSite: SiteItem?

    var body: some View {
        if showingAdd {
            SiteDetailEditView(store: store) {
                showingAdd = false
            }
        } else if let item = editingItem {
            SiteDetailEditView(store: store, existing: item) {
                editingItem = nil
            }
        } else {
            mainList
        }
    }

    @ViewBuilder
    private var mainList: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("返回")
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Spacer()
                Text("编辑网站")
                    .font(.headline)
                Spacer()

                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if store.sites.isEmpty {
                emptyState
            } else {
                siteList
            }
        }
        .frame(width: 420, height: 640)
        .background(.background)
        .overlay {
            if showingDeleteAllAlert {
                confirmOverlay(
                    title: "删除全部网站",
                    message: "将删除所有网站，底部快捷栏会变为空白。此操作无法撤销。",
                    confirmTitle: "删除"
                ) {
                    store.deleteAll()
                    showingDeleteAllAlert = false
                } onCancel: {
                    showingDeleteAllAlert = false
                }
            } else if let site = pendingDeleteSite {
                confirmOverlay(
                    title: "删除网站",
                    message: "将删除「\(site.name)」，此操作无法撤销。",
                    confirmTitle: "删除"
                ) {
                    store.delete(site)
                    pendingDeleteSite = nil
                } onCancel: {
                    pendingDeleteSite = nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("还没有网站")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("点击下方按钮添加你常用的网站")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button(action: { showingAdd = true }) {
                Label("添加网站", systemImage: "plus.circle.fill")
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var siteList: some View {
        VStack(spacing: 0) {
            List {
                ForEach(store.sites) { site in
                    HStack(spacing: 10) {
                        SiteFaviconView(site: site, size: 24, cornerRadius: 6)
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(site.name)
                                .font(.body)
                            Text(site.url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button(action: { editingItem = site }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("编辑 \(site.name)")

                        Button(action: { pendingDeleteSite = site }) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("删除 \(site.name)")
                    }
                    .padding(.vertical, 3)
                }
                .onDelete(perform: store.delete)
            }
            .listStyle(.inset)

            Divider()

            Button(action: { showingDeleteAllAlert = true }) {
                Label("删除全部", systemImage: "trash")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func confirmOverlay(
        title: String,
        message: String,
        confirmTitle: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Spacer()
                    Button("取消", action: onCancel)
                        .buttonStyle(.bordered)
                    Button(confirmTitle, action: onConfirm)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            }
            .padding(16)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
            )
        }
        .transition(.opacity)
    }
}
