import SwiftUI

// MARK: - 底部快捷访问栏
// 常用网站一键跳转，替换当前 WebView 内容
struct QuickAccessBar: View {
    @ObservedObject var viewModel: WebViewModel
    @Binding var inputText: String

    // 快捷按钮配置：显示名称、SF Symbol 图标、对应快捷名
    private let shortcuts: [(name: String, icon: String, key: String)] = [
        ("GPT", "brain.head.profile", "gpt"),
        ("B站", "play.rectangle.fill", "b"),
        ("X", "at", "x"),
        ("微博", "newspaper.fill", "wb"),
        ("YouTube", "play.circle.fill", "yt"),
        ("GitHub", "chevron.left.forwardslash.chevron.right", "gh"),
        ("知乎", "text.bubble.fill", "zhihu"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(shortcuts, id: \.key) { shortcut in
                Button(action: {
                    inputText = shortcut.key
                    viewModel.loadURL(shortcut.key)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: shortcut.icon)
                            .font(.system(size: 14))
                            .frame(height: 16)
                        Text(shortcut.name)
                            .font(.system(size: 9))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help(shortcut.name)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}
