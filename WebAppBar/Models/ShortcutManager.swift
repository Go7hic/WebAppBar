import Foundation

// MARK: - Shortcut key resolver
final class ShortcutManager {
    static let shared = ShortcutManager()

    // Built-in shortcuts (not shown in bar, e.g. search, common sites)
    private let builtins: [String: String] = [
        "g":     "https://www.google.com",
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

    // User sites shortcuts (key -> url), synced by SiteStore
    private var userShortcuts: [String: String] = [:]

    private init() {}

    /// Called by SiteStore when sites change; syncs user shortcuts
    func syncUserSites(_ sites: [SiteItem]) {
        var dict: [String: String] = [:]
        for site in sites {
            dict[site.key] = site.url
        }
        userShortcuts = dict
    }

    /// Resolve user input to full URL string.
    /// Priority: user sites > builtins > existing scheme > add https if has dot > search query
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

    /// All shortcut keys (for suggestions), user sites first
    func allShortcuts() -> [(key: String, url: String)] {
        var merged = builtins
        for (k, v) in userShortcuts { merged[k] = v }
        return merged.sorted { $0.key < $1.key }.map { (key: $0.key, url: $0.value) }
    }

    /// Filter shortcuts by prefix (live suggestions)
    func suggestions(for prefix: String) -> [(key: String, url: String)] {
        guard !prefix.isEmpty else { return [] }
        let lower = prefix.lowercased()
        return allShortcuts().filter { $0.key.hasPrefix(lower) }
    }
}
