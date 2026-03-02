import SwiftUI
import AppKit

// MARK: - 导航栏
struct NavigationBar: View {
    @ObservedObject var viewModel: WebViewModel
    @Binding var inputText: String
    var isInputFocused: FocusState<Bool>.Binding

    @State private var isURLEditing: Bool = false
    @State private var showCopiedFeedback: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            // 后退
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
            }
            .disabled(!viewModel.canGoBack)
            .buttonStyle(.borderless)
            .help("后退")

            // 前进
            Button(action: { viewModel.goForward() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
            }
            .disabled(!viewModel.canGoForward)
            .buttonStyle(.borderless)
            .help("前进")

            // 刷新 / 停止加载
            Button(action: {
                if viewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }) {
                Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help(viewModel.isLoading ? "停止" : "刷新")

            // URL 区域：只读 or 编辑
            if isURLEditing {
                urlEditField
            } else {
                urlReadonlyBar
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - 只读 URL 栏
    private var urlReadonlyBar: some View {
        HStack(spacing: 4) {
            Text(inputText.isEmpty ? "无地址" : inputText)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: copyURL) {
                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(showCopiedFeedback ? .green : .secondary)
            }
            .buttonStyle(.borderless)
            .help("复制地址")
            .disabled(inputText.isEmpty)

            Button(action: { isURLEditing = true }) {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("编辑地址")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
        )
    }

    // MARK: - 编辑 URL 栏
    private var urlEditField: some View {
        HStack(spacing: 4) {
            TextField("输入网址或快捷名（如 gpt, b, x）…", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .focused(isInputFocused)
                .onSubmit {
                    navigateTo(inputText)
                    isURLEditing = false
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: NSTextField.textDidBeginEditingNotification
                    )
                ) { notification in
                    if let textField = notification.object as? NSTextField {
                        DispatchQueue.main.async {
                            textField.currentEditor()?.selectAll(nil)
                        }
                    }
                }

            Button("Go") {
                navigateTo(inputText)
                isURLEditing = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button(action: { isURLEditing = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("取消")
        }
    }

    // MARK: - Helpers
    private func navigateTo(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.loadURL(trimmed)
    }

    private func copyURL() {
        guard !inputText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(inputText, forType: .string)
        withAnimation {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}
