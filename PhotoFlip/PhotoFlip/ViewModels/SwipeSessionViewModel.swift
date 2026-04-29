import Foundation
import UIKit

@Observable
final class SwipeSessionViewModel {
    var photos: [PhotoItem]
    var currentIndex: Int = 0
    var dragOffset: CGSize = .zero

    private struct UndoRecord {
        let index: Int
        let previous: SwipeDecision
    }
    private var undoStack: [UndoRecord] = []
    private let maxUndoDepth = 10

    private let libraryManager: PhotoLibraryManager

    var canUndo: Bool { !undoStack.isEmpty }

    /// True once every photo in the batch has been decided.
    var isComplete: Bool { !photos.isEmpty && currentIndex >= photos.count }

    // Counts apply only to already-decided photos (index < currentIndex).
    var deletedCount: Int {
        photos[0..<min(currentIndex, photos.count)].filter { $0.decision == .delete }.count
    }
    var keptCount: Int {
        photos[0..<min(currentIndex, photos.count)].filter {
            $0.decision == .keep || $0.decision == .favorite
        }.count
    }
    var favoritedCount: Int {
        photos[0..<min(currentIndex, photos.count)].filter { $0.decision == .favorite }.count
    }

    /// Photos marked for deletion that haven't been actually deleted from the library yet.
    var photosToDelete: [PhotoItem] {
        Array(photos[0..<min(currentIndex, photos.count)].filter {
            $0.decision == .delete && !$0.wasDeletedFromLibrary
        })
    }

    init(photos: [PhotoItem], libraryManager: PhotoLibraryManager) {
        self.photos = photos
        self.libraryManager = libraryManager
    }

    func processDecision(_ decision: SwipeDecision) {
        guard currentIndex < photos.count else { return }

        let record = UndoRecord(index: currentIndex, previous: photos[currentIndex].decision)
        undoStack.append(record)
        if undoStack.count > maxUndoDepth { undoStack.removeFirst() }

        photos[currentIndex].decision = decision

        switch decision {
        case .keep:
            HapticManager.shared.impact(.light)
        case .delete:
            HapticManager.shared.impact(.medium)
        case .favorite:
            HapticManager.shared.notify(.success)
        case .undecided:
            break
        }

        currentIndex += 1
    }

    /// Tapping the heart: write to iOS Favorites immediately, then advance the card.
    func markFavorite(for photoItem: PhotoItem) {
        guard currentIndex < photos.count,
              photos[currentIndex].id == photoItem.id else { return }
        Task { try? await libraryManager.setFavorite(asset: photoItem.asset, favorite: true) }
        processDecision(.favorite)
    }

    func undo() {
        guard let record = undoStack.popLast() else { return }
        photos[record.index].decision = record.previous
        currentIndex = record.index
        HapticManager.shared.impact(.light)
    }

    /// After a successful PHPhotoLibrary delete, mark those photos so they don't appear
    /// in photosToDelete again.
    func markActuallyDeleted(ids: Set<String>) {
        for i in 0..<photos.count where ids.contains(photos[i].id) {
            photos[i].wasDeletedFromLibrary = true
        }
    }

    /// Persists IDs of all decided photos to OrganizedPhotosStore.
    func saveOrganizedPhotoIDs() {
        let decidedIDs = photos
            .filter { $0.decision != .undecided }
            .map { $0.id }
        OrganizedPhotosStore.shared.addIDs(decidedIDs)
    }
}
