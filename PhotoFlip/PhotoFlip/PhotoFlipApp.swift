import SwiftUI
import Photos

@main
struct PhotoFlipApp: App {
    @State private var appState = AppState()
    @State private var libraryManager = PhotoLibraryManager()
    @AppStorage("batchSize") private var batchSize: Int = 100
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(libraryManager)
                .preferredColorScheme(appearanceMode.colorScheme)
                .task {
                    // For returning users who already granted permission, auto-load a batch.
                    guard appState.isPermissionGranted, appState.pendingPhotos.isEmpty else { return }
                    let limit = batchSize > 0 ? batchSize : 100
                    let assets = await libraryManager.fetchAllPhotos(limit: limit)
                    appState.pendingPhotos = assets.map { PhotoItem(asset: $0) }
                    appState.sessionStartTime = Date()
                }
        }
    }
}
