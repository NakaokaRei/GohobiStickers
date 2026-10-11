// Capture-only entry point. Compiled in a temporary project copy, never in the shipping app.
import SwiftUI
import UIKit

@main
struct StoreCaptureApp: App {
    @State private var store: StampStore
    static let date = ISO8601DateFormatter().date(from: "2026-10-11T00:00:00Z")!
    static let goal = Goal(id: UUID(uuidString: "03000000-0000-0000-0000-000000000001")!, interval: 3, rewardName: "お気に入りのケーキ")
    static let entries = ["blue_hero", "lemon_hero", "pink_hero"].enumerated().map { index, id in
        StampEntry(presetID: id, createdAt: date.addingTimeInterval(Double(index) * 60))
    }
    static var card: GoalShareCardData {
        GoalShareCardData(placement: GoalPlacement(goal: goal, targetCount: 3), entries: entries,
                          rangeStart: 1, rangeEnd: 3, achievedAt: date)
    }
    init() {
        let road = RewardRoad(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, name: "お勉強ロード", entries: Array(Self.entries.prefix(2)), goals: [Goal(id: Self.goal.id, interval: 2, rewardName: Self.goal.rewardName), Goal(interval: 5, rewardName: "映画を観にいく")])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("store-capture.json")
        let data = StampBookData(roads: [road], appearance: .light)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try! encoder.encode(data).write(to: url)
        _store = State(initialValue: StampStore(fileURL: url, cloudSyncService: nil))
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.arguments.contains("--capture-goal-card") {
                    GoalShareSheet(data: Self.card)
                } else {
                    ContentView().environment(store)
                }
            }
            .preferredColorScheme(.light)
            .environment(\.locale, Locale(identifier: "ja_JP"))
            .task {
                try? await Task.sleep(for: .seconds(3))
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first(where: { $0.isKeyWindow }) {
                    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
                    let png = renderer.pngData { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
                    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let name = ProcessInfo.processInfo.arguments.contains("--open-stamp-editor") ? "stamps" : "road"
                    try? png.write(to: dir.appendingPathComponent(name + ".png"))
                }
                if let card = GoalShareCardRenderer.render(Self.card) {
                    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    try? card.shareImage.pngData.write(to: dir.appendingPathComponent("goal-card.png"))
                }
            }
        }
    }
}

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
