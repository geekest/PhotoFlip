import Foundation

final class OrganizedPhotosStore {
    static let shared = OrganizedPhotosStore()
    private let keptKey = "organizedPhotoIDs"
    private let deletedCountKey = "totalDeletedPhotoCount"

    private init() {}

    func loadIDs() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: keptKey),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(array)
    }

    func addIDs(_ newIDs: some Collection<String>) {
        guard !newIDs.isEmpty else { return }
        var current = loadIDs()
        current.formUnion(newIDs)
        if let data = try? JSONEncoder().encode(Array(current)) {
            UserDefaults.standard.set(data, forKey: keptKey)
        }
    }

    func addDeletedCount(_ n: Int) {
        guard n > 0 else { return }
        let current = UserDefaults.standard.integer(forKey: deletedCountKey)
        UserDefaults.standard.set(current + n, forKey: deletedCountKey)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: keptKey)
        UserDefaults.standard.removeObject(forKey: deletedCountKey)
    }

    var count: Int {
        loadIDs().count
    }

    var deletedCount: Int {
        UserDefaults.standard.integer(forKey: deletedCountKey)
    }
}
