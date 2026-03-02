import SwiftUI

// 用于新建或编辑单个网站
struct SiteDetailEditView: View {
    @ObservedObject var store: SiteStore
    var existing: SiteItem?
    var onDismiss: () -> Void

    @State private var name: String
    @State private var key: String
    @State private var url: String
    @State private var keyError: String?
    @State private var urlError: String?

    init(store: SiteStore, existing: SiteItem? = nil, onDismiss: @escaping () -> Void) {
        self.store = store
        self.existing = existing
        self.onDismiss = onDismiss
        _name = State(initialValue: existing?.name ?? "")
        _key  = State(initialValue: existing?.key  ?? "")
        _url  = State(initialValue: existing?.url  ?? "")
    }

    var isEditing: Bool { existing != nil }

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                Button("取消", action: onDismiss)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)

                Spacer()
                Text(isEditing ? "编辑网站" : "添加网站")
                    .font(.headline)
                Spacer()

                Button("保存") { save() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 图标预览
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08))
                            AsyncImage(url: previewFaviconURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .padding(10)
                                default:
                                    Image(systemName: "globe")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(width: 56, height: 56)
                        Spacer()
                    }
                    .padding(.top, 8)
                    Text("图标会根据网站地址自动获取（favicon.so）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 表单字段
                    VStack(alignment: .leading, spacing: 12) {
                        fieldGroup(label: "显示名称", placeholder: "如：GPT") {
                            TextField("显示名称", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        fieldGroup(label: "简称 (Tab Key)", placeholder: "如：gpt", error: keyError) {
                            TextField("简称", text: $key)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: key) { _, v in
                                    key = v.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                                    validateKey()
                                }
                        }

                        fieldGroup(label: "网站地址", placeholder: "https://example.com", error: urlError) {
                            TextField("URL", text: $url)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: url) { _, _ in validateURL() }
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 420, height: 640)
        .background(.background)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldGroup<Content: View>(
        label: String,
        placeholder: String,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
            if let err = error {
                Text(err)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !key.trimmingCharacters(in: .whitespaces).isEmpty &&
        !url.trimmingCharacters(in: .whitespaces).isEmpty &&
        keyError == nil && urlError == nil
    }

    private func validateKey() {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            keyError = nil; return
        }
        keyError = store.isKeyTaken(trimmed, excluding: existing?.id)
            ? "该简称已被占用" : nil
    }

    private func validateURL() {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { urlError = nil; return }
        urlError = SiteItem.host(from: trimmed) == nil ? "URL 格式不正确" : nil
    }

    private func save() {
        let finalURL = SiteItem.normalizedURLString(from: url)

        let item = SiteItem(
            id: existing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            key: key.trimmingCharacters(in: .whitespaces),
            url: finalURL,
            icon: existing?.icon ?? "globe"
        )
        if isEditing {
            store.update(item)
        } else {
            store.add(item)
        }
        onDismiss()
    }

    private var previewFaviconURL: URL? {
        guard let host = SiteItem.host(from: url) else { return nil }
        return URL(string: "https://favicon.so/\(host)")
    }
}
