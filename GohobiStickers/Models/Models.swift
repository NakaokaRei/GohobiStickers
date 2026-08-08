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
    var imageRevision: UUID?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        presetID: String,
        comment: String = "",
        imageRevision: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.presetID = presetID
        self.comment = comment
        self.imageRevision = imageRevision
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

struct RewardRoad: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var entries: [StampEntry]
    var goals: [Goal]

    init(
        id: UUID = UUID(),
        name: String,
        entries: [StampEntry] = [],
        goals: [Goal] = []
    ) {
        self.id = id
        self.name = name
        self.entries = entries
        self.goals = goals
    }
}

struct StampPreset: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let assetName: String
    let fallbackSymbol: String
    let fallbackColorName: String

    static let all: [StampPreset] = [
        .init(id: "blue_hero", name: L10n.string("preset.blue-hero"), assetName: "stamp_blue_hero", fallbackSymbol: "figure.wave", fallbackColorName: "sky"),
        .init(id: "pink_hero", name: L10n.string("preset.pink-hero"), assetName: "stamp_pink_hero", fallbackSymbol: "person.fill", fallbackColorName: "flower"),
        .init(id: "frog_yellow", name: L10n.string("preset.frog-yellow"), assetName: "stamp_frog_yellow", fallbackSymbol: "face.smiling", fallbackColorName: "sun"),
        .init(id: "frog_green", name: L10n.string("preset.frog-green"), assetName: "stamp_frog_green", fallbackSymbol: "face.smiling", fallbackColorName: "green"),
        .init(id: "lemon_hero", name: L10n.string("preset.lemon-hero"), assetName: "stamp_lemon_hero", fallbackSymbol: "figure.wave", fallbackColorName: "sun"),
        .init(id: "sea_lion", name: L10n.string("preset.sea-lion"), assetName: "stamp_sea_lion", fallbackSymbol: "water.waves", fallbackColorName: "sky"),
        .init(id: "shell", name: L10n.string("preset.shell"), assetName: "stamp_shell", fallbackSymbol: "fossil.shell.fill", fallbackColorName: "sun"),
        .init(id: "penguin_pink", name: L10n.string("preset.penguin-pink"), assetName: "stamp_penguin_pink", fallbackSymbol: "bird.fill", fallbackColorName: "flower"),
        .init(id: "glowing_fish", name: L10n.string("preset.glowing-fish"), assetName: "stamp_glowing_fish", fallbackSymbol: "fish.fill", fallbackColorName: "sky"),
        .init(id: "koala_green", name: L10n.string("preset.koala-green"), assetName: "stamp_koala_green", fallbackSymbol: "pawprint.fill", fallbackColorName: "green"),
        .init(id: "starfish_purple", name: L10n.string("preset.starfish-purple"), assetName: "stamp_starfish_purple", fallbackSymbol: "star.fill", fallbackColorName: "sparkle"),
        .init(id: "butterfly_blue", name: L10n.string("preset.butterfly-blue"), assetName: "stamp_butterfly_blue", fallbackSymbol: "ladybug.fill", fallbackColorName: "sky")
    ]

    private static let legacyAliases = [
        "frog_pink": "frog_yellow",
        "frog_blue": "frog_green"
    ]

    static func preset(for id: String) -> StampPreset {
        let resolvedID = legacyAliases[id] ?? id
        return all.first(where: { $0.id == resolvedID }) ?? all[0]
    }
}

struct StampBookData: Codable, Equatable, Sendable {
    var roads: [RewardRoad]
    var selectedRoadID: UUID
    var appearance: AppAppearance
    var modifiedAt: Date

    var selectedRoad: RewardRoad {
        roads.first(where: { $0.id == selectedRoadID }) ?? roads[0]
    }

    var entries: [StampEntry] { selectedRoad.entries }
    var goals: [Goal] { selectedRoad.goals }

    init(
        roads: [RewardRoad],
        selectedRoadID: UUID? = nil,
        appearance: AppAppearance = .system,
        modifiedAt: Date = .distantPast
    ) {
        let normalizedRoads = roads.isEmpty ? [Self.makeDefaultRoad()] : roads
        self.roads = normalizedRoads
        self.selectedRoadID = selectedRoadID.flatMap { selectedID in
            normalizedRoads.contains(where: { $0.id == selectedID }) ? selectedID : nil
        } ?? normalizedRoads[0].id
        self.appearance = appearance
        self.modifiedAt = modifiedAt
    }

    init(
        entries: [StampEntry],
        goals: [Goal],
        appearance: AppAppearance = .system,
        modifiedAt: Date = .distantPast
    ) {
        let road = RewardRoad(
            name: L10n.string("road.default.name"),
            entries: entries,
            goals: goals
        )
        self.roads = [road]
        self.selectedRoadID = road.id
        self.appearance = appearance
        self.modifiedAt = modifiedAt
    }

    private enum CodingKeys: String, CodingKey {
        case roads
        case selectedRoadID
        case entries
        case goals
        case appearance
        case modifiedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRoads = try container.decodeIfPresent([RewardRoad].self, forKey: .roads) ?? []

        if decodedRoads.isEmpty {
            let legacyEntries = try container.decodeIfPresent([StampEntry].self, forKey: .entries) ?? []
            let legacyGoals = try container.decodeIfPresent([Goal].self, forKey: .goals) ?? []
            let migratedRoad = RewardRoad(
                name: L10n.string("road.default.name"),
                entries: legacyEntries,
                goals: legacyGoals
            )
            roads = [migratedRoad]
            selectedRoadID = migratedRoad.id
        } else {
            roads = decodedRoads
            let decodedSelection = try container.decodeIfPresent(UUID.self, forKey: .selectedRoadID)
            selectedRoadID = decodedSelection.flatMap { selectedID in
                decodedRoads.contains(where: { $0.id == selectedID }) ? selectedID : nil
            } ?? decodedRoads[0].id
        }

        appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .distantPast
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(roads, forKey: .roads)
        try container.encode(selectedRoadID, forKey: .selectedRoadID)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(modifiedAt, forKey: .modifiedAt)
    }

    static let initial = StampBookData(roads: [makeDefaultRoad()], appearance: .system)

    private static func makeDefaultRoad() -> RewardRoad {
        RewardRoad(
            name: L10n.string("road.default.name"),
            goals: [
                Goal(interval: 5, rewardName: L10n.string("default.reward.cake")),
                Goal(interval: 3, rewardName: L10n.string("default.reward.movie")),
                Goal(interval: 2, rewardName: L10n.string("default.reward.book"))
            ]
        )
    }
}
