import SwiftUI

// MARK: - 导航栏
// 包含后退、前进、刷新/停止按钮，URL 输入框，Go 按钮
struct NavigationBar: View {
    @ObservedObject var viewModel: WebViewModel
    @Binding var inputText: String
    var isInputFocused: FocusState<Bool>.Binding

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

            // URL 输入框
            TextField("输入网址或快捷名（如 gpt, b, x）…", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .focused(isInputFocused)
                .onSubmit {
                    navigateTo(inputText)
                }
                // 点击输入框时全选文本，方便快速替换
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

            // Go 按钮
            Button("Go") {
                navigateTo(inputText)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func navigateTo(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.loadURL(trimmed)
    }
}
