import CoreGraphics
import Foundation
import Testing
import UIKit
@testable import GohobiStickers

@MainActor
struct GohobiStickersTests {
    @Test func stampPresetsHaveUniqueIDsAndBundledArtwork() throws {
        let presetIDs = StampPreset.all.map(\.id)

        #expect(Set(presetIDs).count == presetIDs.count)

        for preset in StampPreset.all {
            _ = try #require(UIImage(named: preset.assetName), "Missing app artwork: \(preset.assetName)")
        }

        #expect(StampPreset.preset(for: "frog_pink").id == "frog_yellow")
        #expect(StampPreset.preset(for: "frog_blue").id == "frog_green")
    }

    @Test func widgetStampArtworkIsBundledAndOptimized() throws {
        let plugInsURL = try #require(Bundle.main.builtInPlugInsURL)
        let widgetBundle = try #require(
            Bundle(url: plugInsURL.appending(path: "GohobiStickersWidgetExtension.appex"))
        )

        // The app keeps high-resolution artwork; the widget ships separate, smaller images.
        for preset in StampPreset.all {
            let image = try #require(
                UIImage(named: preset.assetName, in: widgetBundle, compatibleWith: nil),
                "Missing widget artwork: \(preset.assetName)"
            )
            let cgImage = try #require(image.cgImage)
            #expect(max(cgImage.width, cgImage.height) <= 1_024, "Oversized widget artwork: \(preset.assetName)")
        }
    }

    @Test func goalIntervalsBecomeCumulativeTargets() {
        let store = makeStore()

        #expect(store.goals.map(\.interval) == [5, 3, 2])
        #expect(store.goalPlacements.map(\.targetCount) == [5, 8, 10])
    }

    @Test func editingDeletingAndMovingGoalsRecalculatesTargets() {
        let store = makeStore()
        let secondGoal = store.goals[1]

        store.updateGoal(id: secondGoal.id, interval: 4, rewardName: "水族館")
        #expect(store.goalPlacements.map(\.targetCount) == [5, 9, 11])

        store.moveGoals(from: IndexSet(integer: 2), to: 0)
        #expect(store.goals.map(\.interval) == [2, 5, 4])
        #expect(store.goalPlacements.map(\.targetCount) == [2, 7, 11])

        store.deleteGoals(at: IndexSet(integer: 1))
        #expect(store.goalPlacements.map(\.targetCount) == [2, 6])

        let deletedGoal = Goal(interval: 5, rewardName: "ケーキ")
        store.restoreGoals([(offset: 1, goal: deletedGoal)])
        #expect(store.goals.map(\.interval) == [2, 5, 4])
        #expect(store.goalPlacements.map(\.targetCount) == [2, 7, 11])
    }

    @Test func stampCRUDUpdatesTotalAndContent() throws {
        let store = makeStore()
        let addedEntryID = store.addEntry(presetID: "frog_yellow", comment: "  できた！  ")

        #expect(store.totalStampCount == 1)
        let entry = try #require(store.entries.first)
        #expect(entry.id == addedEntryID)
        #expect(entry.comment == "できた！")

        store.updateEntry(id: entry.id, presetID: "blue_hero", comment: "更新")
        #expect(store.entries.first?.presetID == "blue_hero")
        #expect(store.entries.first?.comment == "更新")

        store.deleteEntry(id: entry.id)
        #expect(store.totalStampCount == 0)
    }

    @Test func stampImageIsNormalizedToBoundedJPEG() throws {
        let imageDirectory = temporaryDirectory().appending(path: "images", directoryHint: .isDirectory)
        let imageStore = StampImageStore(directoryURL: imageDirectory)
        let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 2_400, height: 1_200)).image { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2_400, height: 1_200))
        }
        let sourceData = try #require(sourceImage.pngData())

        let normalizedData = try imageStore.normalizedJPEG(from: sourceData)
        let normalizedImage = try #require(UIImage(data: normalizedData)?.cgImage)

        #expect(max(normalizedImage.width, normalizedImage.height) == StampImageStore.maximumPixelLength)
        #expect(normalizedData.starts(with: [0xff, 0xd8]))
        #expect(normalizedData.suffix(2).elementsEqual([0xff, 0xd9]))
    }

    @Test func stampImageCanBeAddedReplacedRemovedAndDeleted() throws {
        let directory = temporaryDirectory()
        let fileURL = directory.appending(path: "stamp-book.json")
        let imageDirectory = directory.appending(path: "images", directoryHint: .isDirectory)
        let imageStore = StampImageStore(directoryURL: imageDirectory)
        let store = StampStore(fileURL: fileURL, imageStore: imageStore)
        let firstImage = try imageStore.normalizedJPEG(from: makeTestImageData(color: .systemBlue))
        let secondImage = try imageStore.normalizedJPEG(from: makeTestImageData(color: .systemGreen))

        let entryID = try store.addEntry(presetID: "shell", comment: "写真", imageData: firstImage)
        var entry = try #require(store.entries.first)
        let firstRevision = try #require(entry.imageRevision)
        #expect(store.image(for: entry) != nil)
        #expect(imageStore.contains(entryID: entryID, revision: firstRevision))

        try store.updateEntry(
            id: entryID,
            presetID: "shell",
            comment: "更新",
            imageChange: .replace(secondImage)
        )
        entry = try #require(store.entries.first)
        let secondRevision = try #require(entry.imageRevision)
        #expect(secondRevision != firstRevision)
        #expect(!imageStore.contains(entryID: entryID, revision: firstRevision))
        #expect(imageStore.contains(entryID: entryID, revision: secondRevision))

        let reloadedStore = StampStore(
            fileURL: fileURL,
            imageStore: StampImageStore(directoryURL: imageDirectory)
        )
        #expect(reloadedStore.entries.first?.imageRevision == secondRevision)
        #expect(reloadedStore.entries.first.flatMap(reloadedStore.image(for:)) != nil)

        try reloadedStore.updateEntry(
            id: entryID,
            presetID: "shell",
            comment: "更新",
            imageChange: .remove
        )
        #expect(reloadedStore.entries.first?.imageRevision == nil)
        #expect(!imageStore.contains(entryID: entryID, revision: secondRevision))

        let deletedEntryID = try reloadedStore.addEntry(
            presetID: "frog_green",
            comment: "",
            imageData: firstImage
        )
        let deletedRevision = try #require(
            reloadedStore.entries.first(where: { $0.id == deletedEntryID })?.imageRevision
        )
        reloadedStore.deleteEntry(id: deletedEntryID)
        #expect(!imageStore.contains(entryID: deletedEntryID, revision: deletedRevision))
    }

    @Test func deletingRoadRemovesItsStampImages() throws {
        let directory = temporaryDirectory()
        let imageStore = StampImageStore(
            directoryURL: directory.appending(path: "images", directoryHint: .isDirectory)
        )
        let store = StampStore(
            fileURL: directory.appending(path: "stamp-book.json"),
            imageStore: imageStore
        )
        let firstRoadID = store.selectedRoadID
        let secondRoadID = store.addRoad(name: "写真ロード")
        let imageData = try imageStore.normalizedJPEG(from: makeTestImageData(color: .systemOrange))
        let entryID = try store.addEntry(presetID: "blue_hero", comment: "", imageData: imageData)
        let revision = try #require(store.entries.first?.imageRevision)

        store.selectRoad(id: firstRoadID)
        store.deleteRoad(id: secondRoadID)

        #expect(!imageStore.contains(entryID: entryID, revision: revision))
    }

    @Test func dataPersistsAndReloads() {
        let url = temporaryURL()
        let firstStore = StampStore(fileURL: url)
        firstStore.addEntry(presetID: "blue_hero", comment: "保存テスト")
        firstStore.addGoal(interval: 7, rewardName: "旅行")

        let reloadedStore = StampStore(fileURL: url)
        #expect(reloadedStore.totalStampCount == 1)
        #expect(reloadedStore.entries.first?.comment == "保存テスト")
        #expect(reloadedStore.goals.last?.interval == 7)
        #expect(reloadedStore.goals.last?.rewardName == "旅行")
    }

    @Test func roadsKeepTheirStampsAndGoalsSeparate() {
        let store = makeStore()
        let firstRoadID = store.selectedRoadID
        store.addEntry(presetID: "blue_hero", comment: "最初のロード")

        let secondRoadID = store.addRoad(name: "運動ロード")
        #expect(store.selectedRoadID == secondRoadID)
        #expect(store.totalStampCount == 0)
        #expect(store.goals.isEmpty)

        store.addEntry(presetID: "shell", comment: "運動できた")
        store.addGoal(interval: 3, rewardName: "アイス")

        store.selectRoad(id: firstRoadID)
        #expect(store.totalStampCount == 1)
        #expect(store.entries.first?.comment == "最初のロード")
        #expect(store.goalPlacements.map(\.targetCount) == [5, 8, 10])

        store.selectRoad(id: secondRoadID)
        #expect(store.totalStampCount == 1)
        #expect(store.entries.first?.presetID == "shell")
        #expect(store.goalPlacements.map(\.targetCount) == [3])
    }

    @Test func roadsAndSelectionPersistAndRoadsCanBeDeleted() {
        let url = temporaryURL()
        let store = StampStore(fileURL: url, cloudSyncService: nil)
        let firstRoadID = store.selectedRoadID
        let secondRoadID = store.addRoad(name: "  おてつだい  ")
        store.addEntry(presetID: "koala_green", comment: "")

        let reloadedStore = StampStore(fileURL: url, cloudSyncService: nil)
        #expect(reloadedStore.roads.count == 2)
        #expect(reloadedStore.selectedRoadID == secondRoadID)
        #expect(reloadedStore.selectedRoad.name == "おてつだい")
        #expect(reloadedStore.totalStampCount == 1)

        reloadedStore.deleteRoad(id: secondRoadID)
        #expect(reloadedStore.roads.count == 1)
        #expect(reloadedStore.selectedRoadID == firstRoadID)

        reloadedStore.deleteRoad(id: firstRoadID)
        #expect(reloadedStore.roads.count == 1)
    }

    @Test func corruptDataFallsBackToInitialContent() throws {
        let url = temporaryURL()
        try Data("not-json".utf8).write(to: url)

        let store = StampStore(fileURL: url)
        #expect(store.totalStampCount == 0)
        #expect(store.goalPlacements.map(\.targetCount) == [5, 8, 10])
    }

    @Test func legacyDataWithoutAppearanceMigratesToSystem() throws {
        let url = temporaryURL()
        let legacyJSON = """
        {
          "entries": [],
          "goals": [{"id":"00000000-0000-0000-0000-000000000001","interval":4,"rewardName":"Test"}]
        }
        """
        try Data(legacyJSON.utf8).write(to: url)

        let store = StampStore(fileURL: url)
        #expect(store.appearance == .system)
        #expect(store.roads.count == 1)
        #expect(store.selectedRoad.name == L10n.string("road.default.name"))
        #expect(store.goalPlacements.map(\.targetCount) == [4])
    }

    @Test func legacyStampWithoutImageRevisionMigratesWithoutAnImage() throws {
        let url = temporaryURL()
        let legacyJSON = """
        {
          "entries": [{
            "id":"00000000-0000-0000-0000-000000000010",
            "presetID":"shell",
            "comment":"Legacy",
            "createdAt":"2026-08-01T00:00:00Z"
          }],
          "goals":[]
        }
        """
        try Data(legacyJSON.utf8).write(to: url)

        let store = StampStore(fileURL: url)

        #expect(store.entries.first?.comment == "Legacy")
        #expect(store.entries.first?.imageRevision == nil)
    }

    @Test func appearancePersists() {
        let url = temporaryURL()
        let store = StampStore(fileURL: url)
        store.setAppearance(.dark)

        let reloadedStore = StampStore(fileURL: url)
        #expect(reloadedStore.appearance == .dark)
    }

    @Test func completingGoalCreatesCelebration() {
        let store = makeStore()

        for _ in 0..<4 {
            store.addEntry(presetID: "blue_hero", comment: "")
            #expect(store.celebration == nil)
        }
        store.addEntry(presetID: "shell", comment: "")

        #expect(store.celebration?.targetCount == 5)
        #expect(store.celebration?.goal.rewardName == L10n.string("default.reward.cake"))

        store.clearCelebration()
        #expect(store.celebration == nil)
    }

    @Test func goalShareCardsUseOnlyTheCurrentGoalInterval() throws {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let entries = (0..<10).map { index in
            StampEntry(
                presetID: StampPreset.all[index % StampPreset.all.count].id,
                createdAt: startDate.addingTimeInterval(Double(index * 60))
            )
        }
        let store = try makeStore(
            entries: entries,
            goals: [
                Goal(interval: 5, rewardName: "ケーキ"),
                Goal(interval: 3, rewardName: "映画"),
                Goal(interval: 2, rewardName: "本")
            ]
        )

        let placements = store.goalPlacements
        let first = try #require(store.goalShareCardData(for: placements[0]))
        let second = try #require(store.goalShareCardData(for: placements[1]))
        let third = try #require(store.goalShareCardData(for: placements[2]))

        #expect((first.rangeStart, first.rangeEnd) == (1, 5))
        #expect((second.rangeStart, second.rangeEnd) == (6, 8))
        #expect((third.rangeStart, third.rangeEnd) == (9, 10))
        #expect(first.entries.map(\.id) == Array(entries[0..<5]).map(\.id))
        #expect(second.entries.map(\.id) == Array(entries[5..<8]).map(\.id))
        #expect(third.entries.map(\.id) == Array(entries[8..<10]).map(\.id))
        #expect(first.achievedAt == entries[4].createdAt)
        #expect(second.achievedAt == entries[7].createdAt)
        #expect(third.achievedAt == entries[9].createdAt)
    }

    @Test func goalShareCardAvailabilityTracksCurrentProgressAndGoalEdits() throws {
        let entries = (0..<10).map { index in
            StampEntry(presetID: StampPreset.all[index % StampPreset.all.count].id)
        }
        let goals = [
            Goal(interval: 5, rewardName: "ケーキ"),
            Goal(interval: 3, rewardName: "映画"),
            Goal(interval: 2, rewardName: "本")
        ]
        let store = try makeStore(entries: Array(entries.prefix(4)), goals: goals)

        #expect(store.goalShareCardData(for: store.goalPlacements[0]) == nil)

        store.addEntry(presetID: "shell", comment: "")
        let achieved = try #require(store.goalShareCardData(for: store.goalPlacements[0]))
        #expect(achieved.entries.count == 5)

        let lastEntry = try #require(store.entries.last)
        store.deleteEntry(id: lastEntry.id)
        #expect(store.goalShareCardData(for: store.goalPlacements[0]) == nil)

        let editedStore = try makeStore(entries: entries, goals: goals)
        let secondGoal = editedStore.goals[1]
        editedStore.updateGoal(id: secondGoal.id, interval: 4, rewardName: "水族館")
        let editedCard = try #require(
            editedStore.goalShareCardData(for: editedStore.goalPlacements[1])
        )
        #expect((editedCard.rangeStart, editedCard.rangeEnd) == (6, 9))
        #expect(editedCard.entries.map(\.id) == Array(entries[5..<9]).map(\.id))
        #expect(editedStore.goalShareCardData(for: editedStore.goalPlacements[2]) == nil)

        let reorderedStore = try makeStore(entries: entries, goals: goals)
        let originalFirstGoalID = reorderedStore.goals[0].id
        reorderedStore.moveGoals(from: IndexSet(integer: 2), to: 0)

        #expect(reorderedStore.goalPlacements.map(\.targetCount) == [2, 7, 10])
        let reorderedPlacement = try #require(
            reorderedStore.goalPlacements.first { $0.id == originalFirstGoalID }
        )
        let reorderedCard = try #require(
            reorderedStore.goalShareCardData(for: reorderedPlacement)
        )
        #expect((reorderedCard.rangeStart, reorderedCard.rangeEnd) == (3, 7))
        #expect(reorderedCard.entries.map(\.id) == Array(entries[2..<7]).map(\.id))
    }

    @Test func goalShareRendererCreatesA1080PixelWideGrowingPNG() throws {
        let smallData = makeShareCardData(entryCount: 1)
        let largeData = makeShareCardData(entryCount: 18)

        let smallCard = try #require(GoalShareCardRenderer.render(smallData))
        let largeCard = try #require(GoalShareCardRenderer.render(largeData))
        let smallImage = try #require(smallCard.image.cgImage)
        let largeImage = try #require(largeCard.image.cgImage)

        #expect(smallImage.width == 1080)
        #expect(largeImage.width == 1080)
        #expect(largeImage.height > smallImage.height)
        #expect(alphaValue(in: smallImage, x: 0, y: 0) == 0)
        #expect(
            alphaValue(
                in: smallImage,
                x: smallImage.width / 2,
                y: smallImage.height / 2
            ) == 255
        )
        #expect(!smallCard.shareImage.pngData.isEmpty)
        #expect(largeCard.shareImage.fileName.hasPrefix("gohobi-goal-18-"))
    }

    @Test func newerCloudDataReplacesTheLocalCopy() async throws {
        let remoteData = StampBookData(
            entries: [StampEntry(presetID: "sea_lion", comment: "iCloud")],
            goals: [Goal(interval: 7, rewardName: "旅行")],
            appearance: .dark,
            modifiedAt: .now.addingTimeInterval(60)
        )
        let syncDate = Date.now
        let service = FakeCloudSyncService(outcome: .downloaded(remoteData, syncDate))
        let store = StampStore(fileURL: temporaryURL(), cloudSyncService: service)

        await store.synchronizeWithCloud()

        #expect(store.entries.first?.comment == "iCloud")
        #expect(store.goalPlacements.map(\.targetCount) == [7])
        #expect(store.appearance == .dark)
        #expect(store.cloudSyncStatus == .synced(syncDate))
    }

    @Test func widgetSnapshotTracksGoalIntervalsAndCompletion() {
        let goals = [
            Goal(interval: 5, rewardName: "ケーキ"),
            Goal(interval: 3, rewardName: "映画"),
            Goal(interval: 2, rewardName: "本")
        ]

        func snapshot(stampCount: Int) -> WidgetSnapshot {
            let entries = (0..<stampCount).map { index in
                StampEntry(presetID: StampPreset.all[index % StampPreset.all.count].id)
            }
            return WidgetSnapshotFactory.make(
                from: StampBookData(entries: entries, goals: goals)
            )
        }

        let empty = snapshot(stampCount: 0)
        #expect(empty.remainingCount == 5)
        #expect(empty.intervalProgress == 0)
        #expect(empty.intervalRequiredCount == 5)

        let beforeFirstGoal = snapshot(stampCount: 4)
        #expect(beforeFirstGoal.remainingCount == 1)
        #expect(beforeFirstGoal.intervalProgress == 4)
        #expect(beforeFirstGoal.intervalRequiredCount == 5)

        let firstGoalReached = snapshot(stampCount: 5)
        #expect(firstGoalReached.nextGoalTarget == 8)
        #expect(firstGoalReached.nextGoalRewardName == "映画")
        #expect(firstGoalReached.remainingCount == 3)
        #expect(firstGoalReached.intervalProgress == 0)
        #expect(firstGoalReached.intervalRequiredCount == 3)

        let betweenGoals = snapshot(stampCount: 6)
        #expect(betweenGoals.remainingCount == 2)
        #expect(betweenGoals.intervalProgress == 1)
        #expect(betweenGoals.intervalRequiredCount == 3)

        let secondGoalReached = snapshot(stampCount: 8)
        #expect(secondGoalReached.nextGoalTarget == 10)
        #expect(secondGoalReached.remainingCount == 2)
        #expect(secondGoalReached.intervalProgress == 0)
        #expect(secondGoalReached.intervalRequiredCount == 2)

        let allGoalsReached = snapshot(stampCount: 10)
        #expect(allGoalsReached.totalStampCount == 10)
        #expect(allGoalsReached.nextGoalTarget == nil)
        #expect(allGoalsReached.remainingCount == nil)
        #expect(allGoalsReached.intervalProgress == nil)
    }

    @Test func widgetSnapshotUsesLatestStampAndRecalculatesAfterGoalChanges() {
        let oldEntry = StampEntry(
            presetID: "frog_pink",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let latestEntry = StampEntry(
            presetID: "sea_lion",
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let data = StampBookData(
            entries: [latestEntry, oldEntry],
            goals: [Goal(interval: 3, rewardName: "映画")]
        )

        let snapshot = WidgetSnapshotFactory.make(from: data)
        #expect(snapshot.latestStampAssetName == "stamp_sea_lion")
        #expect(snapshot.remainingCount == 1)
        #expect(snapshot.intervalProgress == 2)

        let edited = StampBookData(
            entries: [oldEntry],
            goals: [Goal(interval: 5, rewardName: "旅行")]
        )
        let editedSnapshot = WidgetSnapshotFactory.make(from: edited)
        #expect(editedSnapshot.latestStampAssetName == "stamp_frog_yellow")
        #expect(editedSnapshot.remainingCount == 4)
        #expect(editedSnapshot.intervalProgress == 1)
    }

    @Test func widgetSnapshotUsesTheSelectedRoad() {
        let firstRoad = RewardRoad(
            name: "勉強",
            entries: [StampEntry(presetID: "blue_hero")],
            goals: [Goal(interval: 5, rewardName: "ケーキ")]
        )
        let secondRoad = RewardRoad(
            name: "運動",
            entries: [
                StampEntry(presetID: "shell"),
                StampEntry(presetID: "koala_green")
            ],
            goals: [Goal(interval: 3, rewardName: "アイス")]
        )
        let data = StampBookData(
            roads: [firstRoad, secondRoad],
            selectedRoadID: secondRoad.id
        )

        let snapshot = WidgetSnapshotFactory.make(from: data)
        #expect(snapshot.totalStampCount == 2)
        #expect(snapshot.latestStampAssetName == "stamp_koala_green")
        #expect(snapshot.nextGoalRewardName == "アイス")
        #expect(snapshot.remainingCount == 1)
    }

    @Test func widgetSnapshotUsesNewStampAssetNames() {
        let newStamps = [
            (presetID: "frog_yellow", assetName: "stamp_frog_yellow"),
            (presetID: "frog_green", assetName: "stamp_frog_green"),
            (presetID: "lemon_hero", assetName: "stamp_lemon_hero"),
            (presetID: "penguin_pink", assetName: "stamp_penguin_pink"),
            (presetID: "glowing_fish", assetName: "stamp_glowing_fish"),
            (presetID: "koala_green", assetName: "stamp_koala_green"),
            (presetID: "starfish_purple", assetName: "stamp_starfish_purple"),
            (presetID: "butterfly_blue", assetName: "stamp_butterfly_blue")
        ]

        for stamp in newStamps {
            let data = StampBookData(
                entries: [StampEntry(presetID: stamp.presetID)],
                goals: []
            )
            let snapshot = WidgetSnapshotFactory.make(from: data)
            #expect(snapshot.latestStampAssetName == stamp.assetName)
        }
    }

    @Test func widgetHistoryKeepsLatestSixInChronologicalOrder() {
        let entries = (0..<10).map { index in
            StampEntry(presetID: StampPreset.all[index].id,
                       createdAt: Date(timeIntervalSince1970: Double(index)))
        }
        let snapshot = WidgetSnapshotFactory.make(from: StampBookData(
            entries: Array(entries.reversed()), goals: []))
        let expected = entries.suffix(6).map { StampPreset.preset(for: $0.presetID).assetName }
        #expect(snapshot.recentStampAssetNames == expected)
        #expect(snapshot.recentStampAssetNames?.last == snapshot.latestStampAssetName)
        #expect(snapshot.totalStampCount == 10)
        let empty = WidgetSnapshotFactory.make(from: StampBookData(entries: [], goals: []))
        #expect(empty.recentStampAssetNames == [])
    }

    @Test func widgetSnapshotDecodesBeforeHistoryWasAdded() throws {
        let encoded = try JSONEncoder().encode(WidgetSnapshot.empty)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "recentStampAssetNames")
        let legacy = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: legacy)
        #expect(decoded == .empty)
        #expect(decoded.recentStampAssetNames == nil)
    }

    @Test func widgetSnapshotStoreRoundTripsAndRecoversFromCorruption() throws {
        let suiteName = "GohobiStickersTests.WidgetSnapshot.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = WidgetSnapshotStore(defaults: defaults)

        #expect(store.load() == .empty)

        let expected = WidgetSnapshot(
            totalStampCount: 4,
            latestStampAssetName: "stamp_shell",
            nextGoalTarget: 5,
            nextGoalRewardName: "ケーキ",
            remainingCount: 1,
            intervalProgress: 4,
            intervalRequiredCount: 5,
            updatedAt: Date(timeIntervalSince1970: 123)
        )
        #expect(store.save(expected))
        #expect(store.load() == expected)

        defaults.set(
            Data("not-json".utf8),
            forKey: GohobiSharedConfiguration.widgetSnapshotKey
        )
        #expect(store.load() == .empty)
    }

    @Test func stampStorePublishesWidgetSnapshotAfterLocalAndCloudChanges() async throws {
        let suiteName = "GohobiStickersTests.WidgetPublisher.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let snapshotStore = WidgetSnapshotStore(defaults: defaults)

        let remoteData = StampBookData(
            entries: [StampEntry(presetID: "shell", comment: "iCloud")],
            goals: [Goal(interval: 7, rewardName: "旅行")],
            modifiedAt: .now.addingTimeInterval(60)
        )
        let service = FakeCloudSyncService(outcome: .downloaded(remoteData, .now))
        let store = StampStore(
            fileURL: temporaryURL(),
            cloudSyncService: service,
            widgetSnapshotStore: snapshotStore
        )

        store.addEntry(presetID: "frog_green", comment: "")
        #expect(snapshotStore.load().latestStampAssetName == "stamp_frog_green")
        #expect(snapshotStore.load().totalStampCount == 1)

        let localEntry = try #require(store.entries.first)
        store.updateEntry(id: localEntry.id, presetID: "blue_hero", comment: "更新")
        #expect(snapshotStore.load().latestStampAssetName == "stamp_blue_hero")

        store.moveGoals(from: IndexSet(integer: 2), to: 0)
        #expect(snapshotStore.load().nextGoalTarget == 2)
        #expect(snapshotStore.load().remainingCount == 1)

        store.deleteGoals(at: IndexSet(integer: 0))
        #expect(snapshotStore.load().nextGoalTarget == 5)
        #expect(snapshotStore.load().remainingCount == 4)

        await store.synchronizeWithCloud()
        let cloudSnapshot = snapshotStore.load()
        #expect(cloudSnapshot.latestStampAssetName == "stamp_shell")
        #expect(cloudSnapshot.nextGoalRewardName == "旅行")
        #expect(cloudSnapshot.remainingCount == 6)
    }

    @Test func deepLinkAcceptsOnlyTheNewStampRoute() {
        #expect(GohobiDeepLink.route(for: GohobiDeepLink.addStampURL) == .addStamp)
        #expect(GohobiDeepLink.route(for: URL(string: "gohobistickers://stamp/edit")!) == nil)
        #expect(GohobiDeepLink.route(for: URL(string: "gohobistickers://goal/add")!) == nil)
        #expect(GohobiDeepLink.route(for: URL(string: "https://stamp/add")!) == nil)
    }

    @Test func presetCatalogContainsOnlyBundledArtwork() {
        #expect(
            StampPreset.all.map(\.id) == [
                "blue_hero",
                "lemon_hero",
                "pink_hero",
                "frog_yellow",
                "butterfly_blue",
                "frog_green",
                "shell",
                "penguin_pink",
                "koala_green",
                "sea_lion",
                "starfish_purple",
                "glowing_fish"
            ]
        )
    }

    private func makeStore() -> StampStore {
        StampStore(fileURL: temporaryURL(), cloudSyncService: nil)
    }

    private func makeStore(entries: [StampEntry], goals: [Goal]) throws -> StampStore {
        let url = temporaryURL()
        let data = StampBookData(
            entries: entries,
            goals: goals,
            appearance: .system,
            modifiedAt: .now
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(data).write(to: url)
        return StampStore(fileURL: url, cloudSyncService: nil)
    }

    private func makeShareCardData(entryCount: Int) -> GoalShareCardData {
        let entries = (0..<entryCount).map { index in
            StampEntry(presetID: StampPreset.all[index % StampPreset.all.count].id)
        }
        let goal = Goal(interval: entryCount, rewardName: "テストゴール")
        return GoalShareCardData(
            placement: GoalPlacement(goal: goal, targetCount: entryCount),
            entries: entries,
            rangeStart: 1,
            rangeEnd: entryCount,
            achievedAt: entries.last?.createdAt ?? .now
        )
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "GohobiStickersTests-\(UUID().uuidString).json")
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "GohobiStickersImageTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func makeTestImageData(color: UIColor) throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 80)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        }
        return try #require(image.pngData())
    }

    private func alphaValue(in image: CGImage, x: Int, y: Int) -> UInt8? {
        guard let pixelImage = image.cropping(
            to: CGRect(x: x, y: y, width: 1, height: 1)
        ) else {
            return nil
        }

        var rgba = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &rgba,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(pixelImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return rgba[3]
    }
}

private actor FakeCloudSyncService: CloudSyncing {
    let outcome: CloudSyncOutcome

    init(outcome: CloudSyncOutcome) {
        self.outcome = outcome
    }

    func synchronize(_ localData: StampBookData) async throws -> CloudSyncOutcome {
        outcome
    }
}
