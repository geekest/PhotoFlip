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

    private let appState: AppState

    var canUndo: Bool { !undoStack.isEmpty }
    var progress: Double {
        guard !photos.isEmpty else { return 0 }
        return Double(currentIndex) / Double(photos.count)
    }

    init(photos: [PhotoItem], appState: AppState) {
        self.photos = photos
        self.appState = appState
    }

    func processDecision(_ decision: SwipeDecision) {
        guard currentIndex < photos.count else { return }

        let record = UndoRecord(index: currentIndex, previous: photos[currentIndex].decision)
        undoStack.append(record)
        if undoStack.count > maxUndoDepth {
            undoStack.removeFirst()
        }

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

        if currentIndex >= photos.count {
            // Sync decided photos back to AppState before navigating to review
            appState.pendingPhotos = photos
            appState.screen = .review
        }
    }

    func undo() {
        guard let record = undoStack.popLast() else { return }
        photos[record.index].decision = record.previous
        currentIndex = record.index
        HapticManager.shared.impact(.light)
    }
}
