import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class StampStore {
    private(set) var data: StampBookData
    private(set) var celebration: GoalPlacement?
    private(set) var cloudSyncStatus: CloudSyncStatus = .idle
    private let fileURL: URL
    private let cloudSyncService: (any CloudSyncing)?
    private let widgetSnapshotStore: WidgetSnapshotStore?
    private var syncTask: Task<Void, Never>?
    private var isSynchronizing = false
    private var needsAnotherSync = false

    var roads: [RewardRoad] { data.roads }
    var selectedRoadID: UUID { data.selectedRoadID }
    var selectedRoad: RewardRoad { data.selectedRoad }

    var entries: [StampEntry] {
        selectedRoad.entries.sorted { $0.createdAt < $1.createdAt }
    }

    var goals: [Goal] { selectedRoad.goals }
    var totalStampCount: Int { selectedRoad.entries.count }
    var appearance: AppAppearance { data.appearance }

    var goalPlacements: [GoalPlacement] {
        var total = 0
        return goals.map { goal in
            total += max(1, goal.interval)
            return GoalPlacement(goal: goal, targetCount: total)
        }
    }

    init(
        fileURL: URL? = nil,
        cloudSyncService: (any CloudSyncing)? = nil,
        widgetSnapshotStore: WidgetSnapshotStore? = nil
    ) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.cloudSyncService = cloudSyncService
        self.widgetSnapshotStore = widgetSnapshotStore
        self.data = Self.load(from: self.fileURL) ?? .initial
        publishWidgetSnapshot()
    }

    @discardableResult
    func addEntry(presetID: String, comment: String) -> UUID {
        guard let roadIndex = selectedRoadIndex else {
            preconditionFailure("A selected reward road must always exist.")
        }
        let completedGoal = goalPlacements.first { $0.targetCount == totalStampCount + 1 }
        let entry = StampEntry(
            presetID: presetID,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        data.roads[roadIndex].entries.append(entry)
        persistLocalChange()
        celebration = completedGoal
        return entry.id
    }

    func updateEntry(id: UUID, presetID: String, comment: String) {
        guard
            let roadIndex = selectedRoadIndex,
            let entryIndex = data.roads[roadIndex].entries.firstIndex(where: { $0.id == id })
        else { return }
        data.roads[roadIndex].entries[entryIndex].presetID = presetID
        data.roads[roadIndex].entries[entryIndex].comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        persistLocalChange()
    }

    func deleteEntry(id: UUID) {
        guard let roadIndex = selectedRoadIndex else { return }
        data.roads[roadIndex].entries.removeAll { $0.id == id }
        persistLocalChange()
    }

    func addGoal(interval: Int, rewardName: String) {
        guard let roadIndex = selectedRoadIndex else { return }
        data.roads[roadIndex].goals.append(
            Goal(interval: max(1, interval), rewardName: normalizedRewardName(rewardName))
        )
        persistLocalChange()
    }

    func updateGoal(id: UUID, interval: Int, rewardName: String) {
        guard
            let roadIndex = selectedRoadIndex,
            let goalIndex = data.roads[roadIndex].goals.firstIndex(where: { $0.id == id })
        else { return }
        data.roads[roadIndex].goals[goalIndex].interval = max(1, interval)
        data.roads[roadIndex].goals[goalIndex].rewardName = normalizedRewardName(rewardName)
        persistLocalChange()
    }

    func deleteGoals(at offsets: IndexSet) {
        guard let roadIndex = selectedRoadIndex else { return }
        data.roads[roadIndex].goals.remove(atOffsets: offsets)
        persistLocalChange()
    }

    func restoreGoals(_ indexedGoals: [(offset: Int, goal: Goal)]) {
        guard let roadIndex = selectedRoadIndex else { return }
        for item in indexedGoals.sorted(by: { $0.offset < $1.offset }) {
            data.roads[roadIndex].goals.insert(
                item.goal,
                at: min(item.offset, data.roads[roadIndex].goals.count)
            )
        }
        persistLocalChange()
    }

    func moveGoals(from source: IndexSet, to destination: Int) {
        guard let roadIndex = selectedRoadIndex else { return }
        data.roads[roadIndex].goals.move(fromOffsets: source, toOffset: destination)
        persistLocalChange()
    }

    @discardableResult
    func addRoad(name: String) -> UUID {
        let road = RewardRoad(name: normalizedRoadName(name))
        data.roads.append(road)
        data.selectedRoadID = road.id
        celebration = nil
        persistLocalChange()
        return road.id
    }

    func selectRoad(id: UUID) {
        guard data.roads.contains(where: { $0.id == id }), data.selectedRoadID != id else {
            return
        }
        data.selectedRoadID = id
        celebration = nil
        persistLocalChange()
    }

    func updateRoad(id: UUID, name: String) {
        guard let index = data.roads.firstIndex(where: { $0.id == id }) else { return }
        data.roads[index].name = normalizedRoadName(name)
        persistLocalChange()
    }

    func deleteRoad(id: UUID) {
        guard data.roads.count > 1, let index = data.roads.firstIndex(where: { $0.id == id }) else {
            return
        }
        let wasSelected = data.selectedRoadID == id
        data.roads.remove(at: index)
        if wasSelected {
            data.selectedRoadID = data.roads[min(index, data.roads.count - 1)].id
        }
        celebration = nil
        persistLocalChange()
    }

    func setAppearance(_ appearance: AppAppearance) {
        data.appearance = appearance
        persistLocalChange()
    }

    func clearCelebration() {
        celebration = nil
    }

    func goalShareCardData(for placement: GoalPlacement) -> GoalShareCardData? {
        guard let currentPlacement = goalPlacements.first(where: { $0.id == placement.id }) else {
            return nil
        }

        let currentEntries = entries
        let rangeEnd = currentPlacement.targetCount
        let interval = max(1, currentPlacement.goal.interval)
        let rangeStart = rangeEnd - interval + 1
        let lowerBound = rangeStart - 1

        guard
            rangeStart > 0,
            currentEntries.count >= rangeEnd,
            currentEntries.indices.contains(lowerBound),
            currentEntries.indices.contains(rangeEnd - 1)
        else {
            return nil
        }

        let cardEntries = Array(currentEntries[lowerBound..<rangeEnd])
        guard cardEntries.count == interval, let achievedAt = cardEntries.last?.createdAt else {
            return nil
        }

        return GoalShareCardData(
            placement: currentPlacement,
            entries: cardEntries,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            achievedAt: achievedAt
        )
    }

    func synchronizeWithCloud() async {
        guard let cloudSyncService else { return }
        guard !isSynchronizing else {
            needsAnotherSync = true
            return
        }

        isSynchronizing = true
        cloudSyncStatus = .syncing

        repeat {
            needsAnotherSync = false
            let snapshot = data

            do {
                let outcome = try await cloudSyncService.synchronize(snapshot)
                switch outcome {
                case .downloaded(let remoteData, let date):
                    if data.modifiedAt <= snapshot.modifiedAt {
                        data = remoteData
                        save()
                    } else {
                        needsAnotherSync = true
                    }
                    cloudSyncStatus = .synced(date)
                case .uploaded(let date), .unchanged(let date):
                    cloudSyncStatus = .synced(date)
                }
            } catch CloudSyncError.accountUnavailable {
                cloudSyncStatus = .accountUnavailable
            } catch {
                let cocoaError = error as NSError
                cloudSyncStatus = .failed(
                    "\(cocoaError.localizedDescription) [\(cocoaError.domain):\(cocoaError.code)]"
                )
            }

            if data.modifiedAt > snapshot.modifiedAt {
                needsAnotherSync = true
            }
        } while needsAnotherSync

        isSynchronizing = false
    }

    func save() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(data).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure(L10n.format("error.persistence", error.localizedDescription))
        }
        publishWidgetSnapshot()
    }

    private func persistLocalChange() {
        data.modifiedAt = .now
        save()
        scheduleCloudSync()
    }

    private func scheduleCloudSync() {
        guard cloudSyncService != nil else { return }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await self?.synchronizeWithCloud()
        }
    }

    private func publishWidgetSnapshot() {
        guard let widgetSnapshotStore else { return }
        WidgetSnapshotPublisher.publish(data, to: widgetSnapshotStore)
    }

    private func normalizedRewardName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.string("default.reward.generic") : trimmed
    }

    private func normalizedRoadName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.string("road.untitled.name") : trimmed
    }

    private var selectedRoadIndex: Int? {
        data.roads.firstIndex(where: { $0.id == data.selectedRoadID })
    }

    private static func load(from url: URL) -> StampBookData? {
        guard let storedData = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard var decoded = try? decoder.decode(StampBookData.self, from: storedData) else { return nil }

        if decoded.modifiedAt == .distantPast {
            decoded.modifiedAt = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .now
        }
        return decoded
    }

    private static func defaultFileURL() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return root.appending(path: "GohobiStickers", directoryHint: .isDirectory)
            .appending(path: "stamp-book.json", directoryHint: .notDirectory)
    }
}
