import SwiftUI

/// Coordinates describe the empty space in each supplied square illustration.
struct WidgetArtwork {
    let id: String
    let goal: CGRect
    let total: CGRect
    let cheer: CGRect

    var assetName: String { "widget_\(id)" }
    var mediumInk: Color {
        id == "starfish_purple"
            ? Color(red: 1, green: 0.98, blue: 0.88)
            : Color(red: 0.17, green: 0.22, blue: 0.21)
    }
    var mediumAssetName: String { "medium_\(id)" }
    var mediumIsCentered: Bool { ["blue_hero", "butterfly_blue", "penguin_pink"].contains(id) }
    var mediumContentOnRight: Bool { ["shell", "sea_lion"].contains(id) }

    var stampAssetName: String { "stamp_\(id)" }

    static let all: [WidgetArtwork] = [
        .init(id: "koala_green", goal: CGRect(x: 0.04, y: 0.04, width: 0.27, height: 0.27), total: CGRect(x: 0.04, y: 0.48, width: 0.28, height: 0.31), cheer: CGRect(x: 0.34, y: 0.035, width: 0.43, height: 0.13)),
        .init(id: "pink_hero", goal: CGRect(x: 0.06, y: 0.09, width: 0.36, height: 0.28), total: CGRect(x: 0.06, y: 0.42, width: 0.29, height: 0.28), cheer: CGRect(x: 0.43, y: 0.025, width: 0.4, height: 0.12)),
        .init(id: "shell", goal: CGRect(x: 0.06, y: 0.025, width: 0.49, height: 0.18), total: CGRect(x: 0.62, y: 0.025, width: 0.32, height: 0.18), cheer: CGRect(x: 0.69, y: 0.83, width: 0.27, height: 0.12)),
        .init(id: "starfish_purple", goal: CGRect(x: 0.055, y: 0.05, width: 0.36, height: 0.19), total: CGRect(x: 0.055, y: 0.25, width: 0.30, height: 0.17), cheer: CGRect(x: 0.47, y: 0.025, width: 0.40, height: 0.10)),
        .init(id: "glowing_fish", goal: CGRect(x: 0.06, y: 0.76, width: 0.47, height: 0.19), total: CGRect(x: 0.06, y: 0.49, width: 0.32, height: 0.24), cheer: CGRect(x: 0.50, y: 0.025, width: 0.43, height: 0.12)),
        .init(id: "penguin_pink", goal: CGRect(x: 0.04, y: 0.025, width: 0.50, height: 0.17), total: CGRect(x: 0.04, y: 0.36, width: 0.30, height: 0.27), cheer: CGRect(x: 0.59, y: 0.025, width: 0.35, height: 0.10)),
        .init(id: "butterfly_blue", goal: CGRect(x: 0.06, y: 0.045, width: 0.44, height: 0.19), total: CGRect(x: 0.57, y: 0.04, width: 0.37, height: 0.19), cheer: CGRect(x: 0.06, y: 0.23, width: 0.38, height: 0.08)),
        .init(id: "lemon_hero", goal: CGRect(x: 0.05, y: 0.035, width: 0.40, height: 0.20), total: CGRect(x: 0.035, y: 0.27, width: 0.25, height: 0.24), cheer: CGRect(x: 0.53, y: 0.025, width: 0.4, height: 0.10)),
        .init(id: "sea_lion", goal: CGRect(x: 0.61, y: 0.22, width: 0.34, height: 0.24), total: CGRect(x: 0.68, y: 0.49, width: 0.27, height: 0.26), cheer: CGRect(x: 0.54, y: 0.055, width: 0.4, height: 0.12)),
        .init(id: "blue_hero", goal: CGRect(x: 0.05, y: 0.04, width: 0.48, height: 0.20), total: CGRect(x: 0.60, y: 0.035, width: 0.34, height: 0.20), cheer: CGRect(x: 0.045, y: 0.26, width: 0.40, height: 0.11))
    ]

    static func matching(_ stampAssetName: String?) -> WidgetArtwork? {
        all.first { $0.stampAssetName == stampAssetName }
    }
}
