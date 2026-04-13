import Foundation
import Photos

@Observable
final class AppState {
    var isPermissionGranted: Bool
    var pendingPhotos: [PhotoItem] = []
    var sessionStartTime: Date = Date()

    init() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.isPermissionGranted = (status == .authorized || status == .limited)
    }
}
