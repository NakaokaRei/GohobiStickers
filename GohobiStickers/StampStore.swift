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
    private var syncTask: Task<Void, Never>?
    private var isSynchronizing = false
    private var needsAnotherSync = false

    var entries: [StampEntry] {
        data.entries.sorted { $0.createdAt < $1.createdAt }
    }

    var goals: [Goal] { data.goals }
    var totalStampCount: Int { data.entries.count }
    var appearance: AppAppearance { data.appearance }

    var goalPlacements: [GoalPlacement] {
        var total = 0
        return data.goals.map { goal in
            total += max(1, goal.interval)
            return GoalPlacement(goal: goal, targetCount: total)
        }
    }

    init(fileURL: URL? = nil, cloudSyncService: (any CloudSyncing)? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.cloudSyncService = cloudSyncService
        self.data = Self.load(from: self.fileURL) ?? .initial
    }

    func addEntry(presetID: String, comment: String) {
        let completedGoal = goalPlacements.first { $0.targetCount == data.entries.count + 1 }
        data.entries.append(
            StampEntry(presetID: presetID, comment: comment.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        persistLocalChange()
        celebration = completedGoal
    }

    func updateEntry(id: UUID, presetID: String, comment: String) {
        guard let index = data.entries.firstIndex(where: { $0.id == id }) else { return }
        data.entries[index].presetID = presetID
        data.entries[index].comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        persistLocalChange()
    }

    func deleteEntry(id: UUID) {
        data.entries.removeAll { $0.id == id }
        persistLocalChange()
    }

    func addGoal(interval: Int, rewardName: String) {
        data.goals.append(
            Goal(interval: max(1, interval), rewardName: normalizedRewardName(rewardName))
        )
        persistLocalChange()
    }

    func updateGoal(id: UUID, interval: Int, rewardName: String) {
        guard let index = data.goals.firstIndex(where: { $0.id == id }) else { return }
        data.goals[index].interval = max(1, interval)
        data.goals[index].rewardName = normalizedRewardName(rewardName)
        persistLocalChange()
    }

    func deleteGoals(at offsets: IndexSet) {
        data.goals.remove(atOffsets: offsets)
        persistLocalChange()
    }

    func restoreGoals(_ indexedGoals: [(offset: Int, goal: Goal)]) {
        for item in indexedGoals.sorted(by: { $0.offset < $1.offset }) {
            data.goals.insert(item.goal, at: min(item.offset, data.goals.count))
        }
        persistLocalChange()
    }

    func moveGoals(from source: IndexSet, to destination: Int) {
        data.goals.move(fromOffsets: source, toOffset: destination)
        persistLocalChange()
    }

    func setAppearance(_ appearance: AppAppearance) {
        data.appearance = appearance
        persistLocalChange()
    }

    func clearCelebration() {
        celebration = nil
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
                cloudSyncStatus = .failed(error.localizedDescription)
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

    private func normalizedRewardName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.string("default.reward.generic") : trimmed
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
