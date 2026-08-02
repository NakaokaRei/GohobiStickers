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
    @State private var isShowingLaunchExperience: Bool
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _isShowingLaunchExperience = State(
            initialValue: !ProcessInfo.processInfo.arguments.contains("--ui-testing")
        )

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let testURL = FileManager.default.temporaryDirectory
                .appending(path: "GohobiStickersUITests.json", directoryHint: .notDirectory)
            try? FileManager.default.removeItem(at: testURL)
            _store = State(initialValue: StampStore(fileURL: testURL))
            return
        }
        #endif

        _store = State(
            initialValue: StampStore(
                cloudSyncService: CloudKitSyncService(),
                widgetSnapshotStore: WidgetSnapshotStore()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(store)

                if isShowingLaunchExperience {
                    LaunchExperienceView {
                        withAnimation(.easeOut(duration: 0.28)) {
                            isShowingLaunchExperience = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
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
