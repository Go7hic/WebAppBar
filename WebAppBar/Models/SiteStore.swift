import Foundation
import Combine

final class SiteStore: ObservableObject {
    @Published var sites: [SiteItem] {
        didSet {
            save()
            ShortcutManager.shared.syncUserSites(sites)
        }
    }

    private let userDefaultsKey = "webappbar.sites"

    init() {
        if let data = UserDefaults.standard.data(forKey: "webappbar.sites"),
           let decoded = try? JSONDecoder().decode([SiteItem].self, from: data),
           !decoded.isEmpty
        {
            sites = decoded
        } else {
            sites = SiteItem.defaults
        }
        ShortcutManager.shared.syncUserSites(sites)
    }

    // MARK: - CRUD

    func add(_ item: SiteItem) {
        sites.append(item)
    }

    func update(_ item: SiteItem) {
        guard let idx = sites.firstIndex(where: { $0.id == item.id }) else { return }
        sites[idx] = item
    }

    func delete(_ item: SiteItem) {
        sites.removeAll { $0.id == item.id }
    }

    func delete(at offsets: IndexSet) {
        sites.remove(atOffsets: offsets)
    }

    func deleteAll() {
        sites.removeAll()
    }

    func move(from source: IndexSet, to destination: Int) {
        sites.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Validation

    /// Whether key is already used by another site (excluding given id)
    func isKeyTaken(_ key: String, excluding id: UUID? = nil) -> Bool {
        sites.contains { $0.key == key && $0.id != id }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sites) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
