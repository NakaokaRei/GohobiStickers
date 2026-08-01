import Foundation
import Testing
@testable import GohobiStickers

@MainActor
struct GohobiStickersTests {
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
        store.addEntry(presetID: "heart", comment: "  できた！  ")

        #expect(store.totalStampCount == 1)
        let entry = try #require(store.entries.first)
        #expect(entry.comment == "できた！")

        store.updateEntry(id: entry.id, presetID: "crown", comment: "更新")
        #expect(store.entries.first?.presetID == "crown")
        #expect(store.entries.first?.comment == "更新")

        store.deleteEntry(id: entry.id)
        #expect(store.totalStampCount == 0)
    }

    @Test func dataPersistsAndReloads() {
        let url = temporaryURL()
        let firstStore = StampStore(fileURL: url)
        firstStore.addEntry(presetID: "sun", comment: "保存テスト")
        firstStore.addGoal(interval: 7, rewardName: "旅行")

        let reloadedStore = StampStore(fileURL: url)
        #expect(reloadedStore.totalStampCount == 1)
        #expect(reloadedStore.entries.first?.comment == "保存テスト")
        #expect(reloadedStore.goals.last?.interval == 7)
        #expect(reloadedStore.goals.last?.rewardName == "旅行")
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
        #expect(store.goalPlacements.map(\.targetCount) == [4])
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
            store.addEntry(presetID: "sun", comment: "")
            #expect(store.celebration == nil)
        }
        store.addEntry(presetID: "crown", comment: "")

        #expect(store.celebration?.targetCount == 5)
        #expect(store.celebration?.goal.rewardName == L10n.string("default.reward.cake"))

        store.clearCelebration()
        #expect(store.celebration == nil)
    }

    @Test func newerCloudDataReplacesTheLocalCopy() async throws {
        let remoteData = StampBookData(
            entries: [StampEntry(presetID: "rainbow", comment: "iCloud")],
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

    private func makeStore() -> StampStore {
        StampStore(fileURL: temporaryURL(), cloudSyncService: nil)
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "GohobiStickersTests-\(UUID().uuidString).json")
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
