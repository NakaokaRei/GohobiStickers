//
//  GohobiStickersApp.swift
//  GohobiStickers
//
//  Created by NakaokaRei on 2026/08/01.
//

import SwiftUI

@main
struct GohobiStickersApp: App {
    @State private var store = StampStore(cloudSyncService: CloudKitSyncService())
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(store.appearance.colorScheme)
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    await store.synchronizeWithCloud()
                }
        }
    }
}

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}
