//
//  PhotoFlipApp.swift
//  PhotoFlip
//
//  Created by Local on 2026/4/13.
//

import SwiftUI

@main
struct PhotoFlipApp: App {
    @State private var appState = AppState()
    @State private var libraryManager = PhotoLibraryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(libraryManager)
        }
    }
}
