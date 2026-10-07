import Foundation

enum GohobiSharedConfiguration {
    static let appGroupIdentifier = "group.com.nakaokarei.GohobiStickers.7ZJJ7KR6WA"
    static let widgetKind = "GohobiStickersWidget"
    static let widgetSnapshotKey = "widget-snapshot-v1"
}

enum GohobiAppRoute: Equatable, Sendable {
    case addStamp
}

enum GohobiDeepLink {
    static let addStampURL = URL(string: "gohobistickers://stamp/add")!

    static func route(for url: URL) -> GohobiAppRoute? {
        guard
            url.scheme?.lowercased() == "gohobistickers",
            url.host?.lowercased() == "stamp",
            url.path == "/add"
        else {
            return nil
        }
        return .addStamp
    }
}

struct WidgetSnapshot: Codable, Equatable, Sendable {
    let totalStampCount: Int
    let latestStampAssetName: String?
    let nextGoalTarget: Int?
    let nextGoalRewardName: String?
    let remainingCount: Int?
    let intervalProgress: Int?
    let intervalRequiredCount: Int?
    let updatedAt: Date
    // Old snapshots decode without history until the app next publishes. Oldest first.
    var recentStampAssetNames: [String]? = nil

    static let empty = WidgetSnapshot(
        totalStampCount: 0,
        latestStampAssetName: nil,
        nextGoalTarget: nil,
        nextGoalRewardName: nil,
        remainingCount: nil,
        intervalProgress: nil,
        intervalRequiredCount: nil,
        updatedAt: .distantPast
    )
}

struct WidgetSnapshotStore {
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(
        suiteName: GohobiSharedConfiguration.appGroupIdentifier
    )) {
        self.defaults = defaults
    }

    @discardableResult
    func save(_ snapshot: WidgetSnapshot) -> Bool {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else {
            return false
        }
        defaults.set(data, forKey: GohobiSharedConfiguration.widgetSnapshotKey)
        return true
    }

    func load() -> WidgetSnapshot {
        guard
            let data = defaults?.data(forKey: GohobiSharedConfiguration.widgetSnapshotKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}
