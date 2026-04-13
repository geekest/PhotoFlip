import Foundation

@Observable
final class AppState {
    enum AppScreen {
        case permission
        case loading
        case swiping
        case review
        case completion(deleted: Int, kept: Int, duration: TimeInterval)
    }

    var screen: AppScreen = .permission
    var pendingPhotos: [PhotoItem] = []
    var sessionStartTime: Date = Date()
}
