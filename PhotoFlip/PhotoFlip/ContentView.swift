import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isPermissionGranted {
            TabView {
                LibraryView()
                    .tabItem { Label("图库", systemImage: "photo.stack") }

                SwipeSessionView()
                    .tabItem { Label("整理", systemImage: "hand.draw") }

                SettingsView()
                    .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
            }
        } else {
            PermissionView()
        }
    }
}
