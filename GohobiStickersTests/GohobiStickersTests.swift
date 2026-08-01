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

    private func makeStore() -> StampStore {
        StampStore(fileURL: temporaryURL())
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "GohobiStickersTests-\(UUID().uuidString).json")
    }
}
