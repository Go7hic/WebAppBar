import Foundation

// MARK: - 短名称映射管理器
// 支持快捷名称 → 完整 URL 映射，以及智能 URL 补全
final class ShortcutManager {
    static let shared = ShortcutManager()

    // 内置快捷名称映射表（可后续改为 UserDefaults 持久化）
    private var shortcuts: [String: String] = [
        "gpt":   "https://chatgpt.com",
        "g":     "https://chatgpt.com",
        "b":     "https://m.bilibili.com",
        "x":     "https://x.com",
        "wb":    "https://m.weibo.cn",
        "yt":    "https://m.youtube.com",
        "gh":    "https://github.com",
        "rd":    "https://www.reddit.com",
        "wiki":  "https://zh.m.wikipedia.org",
        "zhihu": "https://www.zhihu.com",
        "db":    "https://m.douban.com",
        "tb":    "https://m.taobao.com",
        "jd":    "https://m.jd.com",
        "xhs":   "https://www.xiaohongshu.com",
        "dy":    "https://m.douyin.com",
        "tt":    "https://m.toutiao.com",
        "bing":  "https://www.bing.com",
        "ggl":   "https://www.google.com",
    ]

    private init() {}

    /// 解析用户输入，返回完整 URL 字符串
    /// 优先级：快捷名称 > 已有协议 > 含点号补 https > 当作搜索关键词
    func resolve(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // 1. 快捷名称匹配
        if let mapped = shortcuts[trimmed.lowercased()] {
            return mapped
        }

        // 2. 已包含协议头
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }

        // 3. 包含点号，视为域名，自动补 https://
        if trimmed.contains(".") {
            return "https://\(trimmed)"
        }

        // 4. 其他情况视为搜索关键词，用 Google 搜索
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return "https://www.google.com/search?q=\(encoded)"
    }

    /// 获取所有快捷名称（用于补全提示）
    func allShortcuts() -> [(key: String, url: String)] {
        shortcuts.sorted { $0.key < $1.key }.map { (key: $0.key, url: $0.value) }
    }

    /// 根据前缀过滤快捷名称（输入时实时提示）
    func suggestions(for prefix: String) -> [(key: String, url: String)] {
        guard !prefix.isEmpty else { return [] }
        let lower = prefix.lowercased()
        return shortcuts
            .filter { $0.key.hasPrefix(lower) }
            .sorted { $0.key < $1.key }
            .map { (key: $0.key, url: $0.value) }
    }
}
