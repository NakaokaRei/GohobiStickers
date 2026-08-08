//
//  GohobiStickersApp.swift
//  GohobiStickers
//
//  Created by NakaokaRei on 2026/08/01.
//

import SwiftUI
import UIKit

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
            let testStore = StampStore(fileURL: testURL)
            if ProcessInfo.processInfo.arguments.contains("--ui-testing-long-route") {
                for _ in 0..<12 {
                    testStore.addEntry(presetID: "blue_hero", comment: "")
                }
            }
            if ProcessInfo.processInfo.arguments.contains("--ui-testing-image-stamp") {
                let imageData = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 24))
                    .jpegData(withCompressionQuality: 0.8) { context in
                        UIColor.systemOrange.setFill()
                        context.fill(CGRect(x: 0, y: 0, width: 32, height: 24))
                    }
                _ = try? testStore.addEntry(
                    presetID: "blue_hero",
                    comment: "photo",
                    imageData: imageData
                )
            }
            _store = State(initialValue: testStore)
            return
        }
        #endif

        let imageStore = StampImageStore()
        _store = State(
            initialValue: StampStore(
                cloudSyncService: CloudKitSyncService(imageStore: imageStore),
                widgetSnapshotStore: WidgetSnapshotStore(),
                imageStore: imageStore
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
