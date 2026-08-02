import Foundation

struct GoalShareCardData: Identifiable, Equatable, Sendable {
    let placement: GoalPlacement
    let entries: [StampEntry]
    let rangeStart: Int
    let rangeEnd: Int
    let achievedAt: Date

    var id: UUID { placement.id }
}
