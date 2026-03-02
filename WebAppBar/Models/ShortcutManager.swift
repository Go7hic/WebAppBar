import Foundation

// MARK: - 短名称映射管理器
final class ShortcutManager {
    static let shared = ShortcutManager()

    // 内置快捷名（不在底栏的补充快捷名，如搜索引擎、其他常用站）
    private let builtins: [String: String] = [
        "g":     "https://chatgpt.com",
        "rd":    "https://www.reddit.com",
        "wiki":  "https://zh.m.wikipedia.org",
        "db":    "https://m.douban.com",
        "tb":    "https://m.taobao.com",
        "jd":    "https://m.jd.com",
        "xhs":   "https://www.xiaohongshu.com",
        "dy":    "https://m.douyin.com",
        "tt":    "https://m.toutiao.com",
        "bing":  "https://www.bing.com",
        "ggl":   "https://www.google.com",
    ]

    // 用户 sites 的快捷名（key -> url），由 SiteStore 同步
    private var userShortcuts: [String: String] = [:]

    private init() {}

    /// 由 SiteStore 在 sites 变更时调用，同步用户自定义快捷名
    func syncUserSites(_ sites: [SiteItem]) {
        var dict: [String: String] = [:]
        for site in sites {
            dict[site.key] = site.url
        }
        userShortcuts = dict
    }

    /// 解析用户输入，返回完整 URL 字符串
    /// 优先级：用户 sites > 内置快捷名 > 已有协议 > 含点号补 https > 当作搜索关键词
    func resolve(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let lower = trimmed.lowercased()

        if let mapped = userShortcuts[lower] { return mapped }
        if let mapped = builtins[lower] { return mapped }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }

        if trimmed.contains(".") {
            return "https://\(trimmed)"
        }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return "https://www.google.com/search?q=\(encoded)"
    }

    /// 获取所有快捷名（用于补全提示），用户 sites 优先
    func allShortcuts() -> [(key: String, url: String)] {
        var merged = builtins
        for (k, v) in userShortcuts { merged[k] = v }
        return merged.sorted { $0.key < $1.key }.map { (key: $0.key, url: $0.value) }
    }

    /// 根据前缀过滤快捷名（输入时实时提示）
    func suggestions(for prefix: String) -> [(key: String, url: String)] {
        guard !prefix.isEmpty else { return [] }
        let lower = prefix.lowercased()
        return allShortcuts().filter { $0.key.hasPrefix(lower) }
    }
}
