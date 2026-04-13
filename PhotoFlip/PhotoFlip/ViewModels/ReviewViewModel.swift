import Foundation

@Observable
final class ReviewViewModel {
    var photos: [PhotoItem]
    private let libraryManager: PhotoLibraryManager
    private let appState: AppState
    private let sessionStartTime: Date

    var toDelete: [PhotoItem] {
        photos.filter { $0.decision == .delete }
    }

    init(photos: [PhotoItem], libraryManager: PhotoLibraryManager, appState: AppState, sessionStartTime: Date) {
        self.photos = photos
        self.libraryManager = libraryManager
        self.appState = appState
        self.sessionStartTime = sessionStartTime
    }

    func removeFromDelete(id: String) {
        if let idx = photos.firstIndex(where: { $0.id == id }) {
            photos[idx].decision = .undecided
        }
    }

    func confirmDelete() async throws {
        let assetsToDelete = toDelete.map { $0.asset }
        try await libraryManager.deleteAssets(assetsToDelete)

        let deletedCount = assetsToDelete.count
        let keptCount = photos.filter { $0.decision == .keep || $0.decision == .favorite }.count
        let duration = Date().timeIntervalSince(sessionStartTime)

        appState.screen = .completion(deleted: deletedCount, kept: keptCount, duration: duration)
    }
}
