//
//  ContentView.swift
//  PhotoFlip
//
//  Created by Local on 2026/4/13.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        switch appState.screen {
        case .permission:
            PermissionView()
        case .loading:
            ProgressView("加载中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .swiping:
            SwipeSessionView()
        case .review:
            ReviewView()
        case .completion(let deleted, let kept, let duration):
            CompletionView(deleted: deleted, kept: kept, duration: duration)
        }
    }
}
