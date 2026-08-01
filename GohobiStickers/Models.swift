import Foundation

enum AppAppearance: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case dark
    case light

    var id: String { rawValue }
}

struct StampEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var presetID: String
    var comment: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        presetID: String,
        comment: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.presetID = presetID
        self.comment = comment
        self.createdAt = createdAt
    }
}

struct Goal: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var interval: Int
    var rewardName: String

    init(id: UUID = UUID(), interval: Int, rewardName: String) {
        self.id = id
        self.interval = max(1, interval)
        self.rewardName = rewardName
    }
}

struct GoalPlacement: Identifiable, Equatable, Sendable {
    let goal: Goal
    let targetCount: Int

    var id: UUID { goal.id }
}

struct StampPreset: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let assetName: String
    let fallbackSymbol: String
    let fallbackColorName: String

    static let all: [StampPreset] = [
        .init(id: "sun", name: L10n.string("preset.sun"), assetName: "stamp_sun", fallbackSymbol: "sun.max.fill", fallbackColorName: "sun"),
        .init(id: "flower", name: L10n.string("preset.flower"), assetName: "stamp_flower", fallbackSymbol: "camera.macro", fallbackColorName: "flower"),
        .init(id: "crown", name: L10n.string("preset.crown"), assetName: "stamp_crown", fallbackSymbol: "crown.fill", fallbackColorName: "crown"),
        .init(id: "heart", name: L10n.string("preset.heart"), assetName: "stamp_heart", fallbackSymbol: "heart.fill", fallbackColorName: "heart"),
        .init(id: "sparkle", name: L10n.string("preset.sparkle"), assetName: "stamp_sparkle", fallbackSymbol: "sparkles", fallbackColorName: "sparkle"),
        .init(id: "rainbow", name: L10n.string("preset.rainbow"), assetName: "stamp_rainbow", fallbackSymbol: "rainbow", fallbackColorName: "rainbow")
    ]

    static func preset(for id: String) -> StampPreset {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

struct StampBookData: Codable, Equatable, Sendable {
    var entries: [StampEntry]
    var goals: [Goal]
    var appearance: AppAppearance
    var modifiedAt: Date

    init(
        entries: [StampEntry],
        goals: [Goal],
        appearance: AppAppearance = .system,
        modifiedAt: Date = .distantPast
    ) {
        self.entries = entries
        self.goals = goals
        self.appearance = appearance
        self.modifiedAt = modifiedAt
    }

    private enum CodingKeys: String, CodingKey {
        case entries
        case goals
        case appearance
        case modifiedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = try container.decodeIfPresent([StampEntry].self, forKey: .entries) ?? []
        goals = try container.decodeIfPresent([Goal].self, forKey: .goals) ?? []
        appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .distantPast
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
        try container.encode(goals, forKey: .goals)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(modifiedAt, forKey: .modifiedAt)
    }

    static let initial = StampBookData(
        entries: [],
        goals: [
            Goal(interval: 5, rewardName: L10n.string("default.reward.cake")),
            Goal(interval: 3, rewardName: L10n.string("default.reward.movie")),
            Goal(interval: 2, rewardName: L10n.string("default.reward.book"))
        ],
        appearance: .system
    )
}
