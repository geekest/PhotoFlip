import SwiftUI

private enum AppTab: Hashable {
    case library, swipe, settings
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .swipe

    var body: some View {
        if appState.isPermissionGranted {
            TabView(selection: $selectedTab) {
                LibraryView()
                    .tabItem { Label("图库", systemImage: "photo.on.rectangle.angled") }
                    .tag(AppTab.library)

                SwipeSessionView()
                    .tabItem { Label("整理", systemImage: "rectangle.stack") }
                    .tag(AppTab.swipe)

                SettingsView()
                    .tabItem { Label("设置", systemImage: "gearshape") }
                    .tag(AppTab.settings)
            }
            .tint(.accentColor)
        } else {
            PermissionView()
        }
    }
}

#Preview("未授权") {
    let appState: AppState = {
        let s = AppState()
        s.isPermissionGranted = false
        return s
    }()
    ContentView()
        .environment(appState)
        .environment(PhotoLibraryManager())
}

#Preview("已授权") {
    let appState: AppState = {
        let s = AppState()
        s.isPermissionGranted = true
        return s
    }()
    ContentView()
        .environment(appState)
        .environment(PhotoLibraryManager())
}
