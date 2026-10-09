import SwiftUI
import UIKit
import WidgetKit

@main
final class ReviewApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: VStack(spacing: 24) {
            Text("Medium Widget • Design review").font(.headline)
            review("pink_hero", history: true).frame(width: 364, height: 170).clipShape(RoundedRectangle(cornerRadius: 22))
            review("penguin_pink", history: true).frame(width: 364, height: 170).clipShape(RoundedRectangle(cornerRadius: 22))
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(white: 0.95)))
        self.window = window
        window.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.capture() }
        return true
    }
    func review(_ id: String, history: Bool, remaining: Int? = 36, total: Int = 39) -> some View {
        let assets = ["stamp_shell", "stamp_blue_hero", "stamp_penguin_pink", "stamp_lemon_hero", "stamp_butterfly_blue", "stamp_" + id]
        let snapshot = WidgetSnapshot(totalStampCount: total, latestStampAssetName: "stamp_" + id, nextGoalTarget: remaining.map { total + $0 }, nextGoalRewardName: "Reward", remainingCount: remaining, intervalProgress: 0, intervalRequiredCount: remaining, updatedAt: .now, recentStampAssetNames: history ? assets : [])
        return PrintedTrailMediumWidgetView(entry: GohobiTimelineEntry(date: .now, snapshot: snapshot))
    }
    func capture() {
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for id in ["pink_hero", "penguin_pink"] {
            for (name, history, remaining, total, width, height) in [
                ("reference", false, Optional(36), 39, 364.0, 182.0),
                ("history", true, Optional(36), 39, 364.0, 170.0),
                ("empty", false, Optional(5), 0, 320.0, 148.0),
                ("no-goal", true, Optional<Int>.none, 39, 364.0, 170.0),
                ("large-count", true, Optional(12345), 99999, 320.0, 148.0)
            ] {
                let view = review(id, history: history, remaining: remaining, total: total).frame(width: width, height: height)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 3
                if let png = renderer.uiImage?.pngData() { try! png.write(to: output.appendingPathComponent("\(id)-\(name).png")) }
            }
        }
        let fonts = UIFont.familyNames.filter { $0.localizedCaseInsensitiveContains("maru") || $0.localizedCaseInsensitiveContains("tsuku") }.map { $0 + ": " + UIFont.fontNames(forFamilyName: $0).joined(separator: ", ") }
        try! fonts.joined(separator: "\n").write(to: output.appendingPathComponent("fonts.txt"), atomically: true, encoding: .utf8)
    }
}
