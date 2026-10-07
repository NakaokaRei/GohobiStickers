import Foundation
import WidgetKit

enum WidgetSnapshotFactory {
    static func make(from data: StampBookData, updatedAt: Date = .now) -> WidgetSnapshot {
        let entries = data.entries.sorted { $0.createdAt < $1.createdAt }
        let latestAssetName = entries.last.map { entry in
            StampPreset.preset(for: entry.presetID).assetName
        }
        let recentAssets = entries.suffix(6).map { StampPreset.preset(for: $0.presetID).assetName }
        let totalStampCount = entries.count

        var cumulativeTarget = 0
        var previousTarget = 0

        for goal in data.goals {
            let requiredCount = max(1, goal.interval)
            cumulativeTarget += requiredCount

            if cumulativeTarget > totalStampCount {
                return WidgetSnapshot(
                    totalStampCount: totalStampCount,
                    latestStampAssetName: latestAssetName,
                    nextGoalTarget: cumulativeTarget,
                    nextGoalRewardName: goal.rewardName,
                    remainingCount: cumulativeTarget - totalStampCount,
                    intervalProgress: max(0, totalStampCount - previousTarget),
                    intervalRequiredCount: requiredCount,
                    updatedAt: updatedAt,
                    recentStampAssetNames: recentAssets
                )
            }

            previousTarget = cumulativeTarget
        }

        return WidgetSnapshot(
            totalStampCount: totalStampCount,
            latestStampAssetName: latestAssetName,
            nextGoalTarget: nil,
            nextGoalRewardName: nil,
            remainingCount: nil,
            intervalProgress: nil,
            intervalRequiredCount: nil,
            updatedAt: updatedAt,
            recentStampAssetNames: recentAssets
        )
    }
}

@MainActor
enum WidgetSnapshotPublisher {
    static func publish(_ data: StampBookData, to store: WidgetSnapshotStore) {
        guard store.save(WidgetSnapshotFactory.make(from: data)) else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: GohobiSharedConfiguration.widgetKind)
    }
}
