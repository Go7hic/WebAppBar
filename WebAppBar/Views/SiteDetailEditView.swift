import SwiftUI

// New or edit single site
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
            // Header
            HStack {
                Button("Cancel", action: onDismiss)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)

                Spacer()
                Text(isEditing ? "Edit site" : "Add site")
                    .font(.headline)
                Spacer()

                Button("Save") { save() }
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
                    // Icon preview
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
                    Text("Icon is fetched automatically from the site URL (favicon.so)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Form fields
                    VStack(alignment: .leading, spacing: 12) {
                        fieldGroup(label: "Display name", placeholder: "e.g. GPT") {
                            TextField("Display name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        fieldGroup(label: "Shortcut (Tab key)", placeholder: "e.g. gpt", error: keyError) {
                            TextField("Shortcut", text: $key)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: key) { _, v in
                                    key = v.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                                    validateKey()
                                }
                        }

                        fieldGroup(label: "URL", placeholder: "https://example.com", error: urlError) {
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
            ? "This shortcut is already in use" : nil
    }

    private func validateURL() {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { urlError = nil; return }
        urlError = SiteItem.host(from: trimmed) == nil ? "Invalid URL format" : nil
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
