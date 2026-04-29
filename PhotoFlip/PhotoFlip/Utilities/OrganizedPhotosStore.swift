import Foundation

final class OrganizedPhotosStore {
    static let shared = OrganizedPhotosStore()
    private let key = "organizedPhotoIDs"

    private init() {}

    func loadIDs() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: key),
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
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    var count: Int {
        loadIDs().count
    }
}
