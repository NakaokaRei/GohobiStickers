import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class StampStore {
    private(set) var data: StampBookData
    private let fileURL: URL

    var entries: [StampEntry] {
        data.entries.sorted { $0.createdAt < $1.createdAt }
    }

    var goals: [Goal] { data.goals }
    var totalStampCount: Int { data.entries.count }

    var goalPlacements: [GoalPlacement] {
        var total = 0
        return data.goals.map { goal in
            total += max(1, goal.interval)
            return GoalPlacement(goal: goal, targetCount: total)
        }
    }

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.data = Self.load(from: self.fileURL) ?? .initial
    }

    func addEntry(presetID: String, comment: String) {
        data.entries.append(
            StampEntry(presetID: presetID, comment: comment.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        save()
    }

    func updateEntry(id: UUID, presetID: String, comment: String) {
        guard let index = data.entries.firstIndex(where: { $0.id == id }) else { return }
        data.entries[index].presetID = presetID
        data.entries[index].comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deleteEntry(id: UUID) {
        data.entries.removeAll { $0.id == id }
        save()
    }

    func addGoal(interval: Int, rewardName: String) {
        data.goals.append(
            Goal(interval: max(1, interval), rewardName: normalizedRewardName(rewardName))
        )
        save()
    }

    func updateGoal(id: UUID, interval: Int, rewardName: String) {
        guard let index = data.goals.firstIndex(where: { $0.id == id }) else { return }
        data.goals[index].interval = max(1, interval)
        data.goals[index].rewardName = normalizedRewardName(rewardName)
        save()
    }

    func deleteGoals(at offsets: IndexSet) {
        data.goals.remove(atOffsets: offsets)
        save()
    }

    func moveGoals(from source: IndexSet, to destination: Int) {
        data.goals.move(fromOffsets: source, toOffset: destination)
        save()
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

    private func normalizedRewardName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.string("default.reward.generic") : trimmed
    }

    private static func load(from url: URL) -> StampBookData? {
        guard let storedData = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(StampBookData.self, from: storedData)
    }

    private static func defaultFileURL() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return root.appending(path: "GohobiStickers", directoryHint: .isDirectory)
            .appending(path: "stamp-book.json", directoryHint: .notDirectory)
    }
}
