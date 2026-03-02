import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct SiteItem: Identifiable, Codable, Equatable, Hashable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .siteItem)
    }
    var id: UUID
    var name: String
    var key: String
    var url: String
    var icon: String

    init(id: UUID = UUID(), name: String, key: String, url: String, icon: String) {
        self.id = id
        self.name = name
        self.key = key
        self.url = url
        self.icon = icon
    }

    static func normalizedURLString(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        return "https://\(trimmed)"
    }

    static func host(from input: String) -> String? {
        let normalized = normalizedURLString(from: input)
        guard !normalized.isEmpty else { return nil }
        return URLComponents(string: normalized)?.host
    }

    var faviconURL: URL? {
        guard let host = Self.host(from: url) else { return nil }
        return URL(string: "https://favicon.so/\(host)")
    }
}

extension UTType {
    static let siteItem = UTType(exportedAs: "com.webappbar.siteitem")
}

extension SiteItem {
    static let defaults: [SiteItem] = [
        SiteItem(name: "X",       key: "x",     url: "https://x.com",            icon: "at"),
        SiteItem(name: "Google",  key: "ggl",   url: "https://www.google.com",   icon: "globe"),
        SiteItem(name: "GPT",     key: "gpt",   url: "https://chatgpt.com",      icon: "brain.head.profile"),
        SiteItem(name: "Claude",  key: "claude", url: "https://claude.ai",      icon: "brain.head.profile"),
        SiteItem(name: "Bili",     key: "b",     url: "https://m.bilibili.com",   icon: "play.rectangle.fill"),
        SiteItem(name: "GitHub",  key: "gh",    url: "https://github.com",       icon: "chevron.left.forwardslash.chevron.right"),
      
    ]
}
