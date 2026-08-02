//
//  GohobiStickersApp.swift
//  GohobiStickers
//
//  Created by NakaokaRei on 2026/08/01.
//

import SwiftUI

@main
struct GohobiStickersApp: App {
    @State private var store: StampStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let testURL = FileManager.default.temporaryDirectory
                .appending(path: "GohobiStickersUITests.json", directoryHint: .notDirectory)
            try? FileManager.default.removeItem(at: testURL)
            _store = State(initialValue: StampStore(fileURL: testURL))
            return
        }
        #endif

        _store = State(initialValue: StampStore(cloudSyncService: CloudKitSyncService()))
    }

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
