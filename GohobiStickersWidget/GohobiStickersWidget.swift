import SwiftUI
import WidgetKit

@main
struct GohobiStickersWidgetBundle: WidgetBundle {
    var body: some Widget {
        GohobiStickersWidget()
    }
}

struct GohobiStickersWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: GohobiSharedConfiguration.widgetKind,
            provider: GohobiTimelineProvider()
        ) { entry in
            GohobiWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetPalette.background
                }
                .widgetURL(GohobiDeepLink.addStampURL)
        }
        .configurationDisplayName(WidgetL10n.string("widget.configuration.name"))
        .description(WidgetL10n.string("widget.configuration.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct GohobiTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let artwork: WidgetArtwork
    let recentStampAssetNames: [String]

    init(date: Date, snapshot: WidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
        // Select once per timeline entry, never during SwiftUI body evaluation.
        artwork = WidgetArtwork.matching(snapshot.latestStampAssetName)
            ?? WidgetArtwork.all.randomElement()!
        recentStampAssetNames = (snapshot.recentStampAssetNames ?? snapshot.latestStampAssetName.map { [$0] } ?? []).suffix(6).map {
            (WidgetArtwork.matching($0) ?? WidgetArtwork.all.randomElement()!).stampAssetName
        }
    }
}

struct GohobiTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GohobiTimelineEntry {
        GohobiTimelineEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (GohobiTimelineEntry) -> Void
    ) {
        completion(GohobiTimelineEntry(date: .now, snapshot: snapshot(for: context)))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<GohobiTimelineEntry>) -> Void
    ) {
        let entry = GohobiTimelineEntry(date: .now, snapshot: WidgetSnapshotStore().load())
        let nextRefresh = Date.now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func snapshot(for context: Context) -> WidgetSnapshot {
        context.isPreview ? .preview : WidgetSnapshotStore().load()
    }
}

private extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        totalStampCount: 7,
        latestStampAssetName: "stamp_frog_green",
        nextGoalTarget: 8,
        nextGoalRewardName: WidgetL10n.string("widget.preview.reward"),
        remainingCount: 1,
        intervalProgress: 2,
        intervalRequiredCount: 3,
        updatedAt: .now,
        recentStampAssetNames: ["stamp_shell", "stamp_blue_hero", "stamp_penguin_pink", "stamp_lemon_hero", "stamp_butterfly_blue", "stamp_koala_green", "stamp_frog_green"]
    )

    static let emptyWithGoal = WidgetSnapshot(
        totalStampCount: 0,
        latestStampAssetName: nil,
        nextGoalTarget: 5,
        nextGoalRewardName: WidgetL10n.string("widget.preview.reward"),
        remainingCount: 5,
        intervalProgress: 0,
        intervalRequiredCount: 5,
        updatedAt: .now
    )

    static let noGoalPreview = WidgetSnapshot(
        totalStampCount: 10,
        latestStampAssetName: "stamp_shell",
        nextGoalTarget: nil,
        nextGoalRewardName: nil,
        remainingCount: nil,
        intervalProgress: nil,
        intervalRequiredCount: nil,
        updatedAt: .now
    )
}

#Preview("Small", as: .systemSmall) {
    GohobiStickersWidget()
} timeline: {
    GohobiTimelineEntry(date: .now, snapshot: .preview)
}

#Preview("Medium", as: .systemMedium) {
    GohobiStickersWidget()
} timeline: {
    GohobiTimelineEntry(date: .now, snapshot: .preview)
}

#Preview("Small Empty", as: .systemSmall) {
    GohobiStickersWidget()
} timeline: {
    GohobiTimelineEntry(date: .now, snapshot: .emptyWithGoal)
}

#Preview("Medium Empty", as: .systemMedium) {
    GohobiStickersWidget()
} timeline: {
    GohobiTimelineEntry(date: .now, snapshot: .emptyWithGoal)
}

#Preview("Small No Goal", as: .systemSmall) {
    GohobiStickersWidget()
} timeline: {
    GohobiTimelineEntry(date: .now, snapshot: .noGoalPreview)
}

#Preview("Medium No Goal", as: .systemMedium) {
    GohobiStickersWidget()
} timeline: {
    GohobiTimelineEntry(date: .now, snapshot: .noGoalPreview)
}
