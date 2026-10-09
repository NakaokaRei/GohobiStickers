import SwiftUI

struct GoalAchievementCard: View {
    static let width: CGFloat = 360
    static let cornerRadius: CGFloat = 34
    private static let columns = 3
    private static let stampSize: CGFloat = 74
    private static let columnSpacing: CGFloat = 20
    private static let rowSpacing: CGFloat = 28

    let data: GoalShareCardData

    private let cardBackground = Color(red: 0.99, green: 0.96, blue: 0.89)
    private let cardInk = Color(red: 0.18, green: 0.20, blue: 0.24)

    var body: some View {
        VStack(spacing: 22) {
            header
            stampGrid
            achievementDetails
            brand
        }
        .padding(26)
        .frame(width: Self.width)
        .background {
            ZStack {
                LinearGradient(
                    colors: [cardBackground, Color(red: 1, green: 0.91, blue: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(AppColors.sun.opacity(0.16))
                    .frame(width: 190, height: 190)
                    .offset(x: 140, y: -180)
                Circle()
                    .fill(AppColors.mint.opacity(0.12))
                    .frame(width: 150, height: 150)
                    .offset(x: -150, y: 220)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 3)
        }
        .compositingGroup()
        .shadow(color: cardInk.opacity(0.15), radius: 18, y: 10)
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("goal-achievement-card")
    }

    private var header: some View {
        VStack(spacing: 12) {
            CelebrationCompanion(id: data.placement.id, compact: true)

            Text(L10n.string("goal.share.card.title"))
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(cardInk)

            RewardRibbon {
                Text(data.placement.goal.rewardName)
                    .font(.title2.bold())
            }

            Text(L10n.format("goal.share.card.range", data.rangeStart, data.rangeEnd))
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.mint)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.mint.opacity(0.12), in: Capsule())
        }
    }

    private var stampGrid: some View {
        Grid(horizontalSpacing: Self.columnSpacing, verticalSpacing: Self.rowSpacing) {
            ForEach(stampRows.indices, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<Self.columns, id: \.self) { columnIndex in
                        let entryIndex = rowIndex * Self.columns + (rowIndex.isMultiple(of: 2) ? columnIndex : Self.columns - 1 - columnIndex)
                        if data.entries.indices.contains(entryIndex) {
                            StampArtwork(
                                preset: .preset(for: data.entries[entryIndex].presetID),
                                size: Self.stampSize
                            )
                        } else {
                            Color.clear
                                .frame(width: Self.stampSize, height: Self.stampSize)
                        }
                    }
                }
            }
        }
        .background {
            Canvas { context, size in
                guard !data.entries.isEmpty else { return }
                let stepX = Self.stampSize + Self.columnSpacing
                let stepY = Self.stampSize + Self.rowSpacing
                func center(_ index: Int) -> CGPoint {
                    let row = index / Self.columns
                    let column = row.isMultiple(of: 2) ? index % Self.columns : Self.columns - 1 - index % Self.columns
                    return CGPoint(x: Self.stampSize / 2 + CGFloat(column) * stepX,
                                   y: Self.stampSize / 2 + CGFloat(row) * stepY)
                }
                var path = Path()
                let first = center(0)
                path.move(to: CGPoint(x: -8, y: -10))
                path.addQuadCurve(to: first, control: CGPoint(x: -8, y: first.y))
                for index in 1..<data.entries.count {
                    let previous = center(index - 1)
                    let next = center(index)
                    if index.isMultiple(of: Self.columns) {
                        let bendX: CGFloat = (index / Self.columns).isMultiple(of: 2) ? -16 : size.width + 16
                        path.addCurve(to: next,
                                      control1: CGPoint(x: bendX, y: previous.y),
                                      control2: CGPoint(x: bendX, y: next.y))
                    } else {
                        path.addLine(to: next)
                    }
                }
                let lastIndex = data.entries.count - 1
                let last = center(lastIndex)
                let direction: CGFloat = (lastIndex / Self.columns).isMultiple(of: 2) ? 1 : -1
                // Mirror the entrance curve downward, using one continuous, broad bend.
                let exitX = last.x + direction * (Self.stampSize / 2 + 8)
                path.addQuadCurve(to: CGPoint(x: exitX, y: size.height + 10),
                                  control: CGPoint(x: exitX, y: last.y))
                context.stroke(path, with: .color(Color(red: 0.64, green: 0.51, blue: 0.35)),
                               style: StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: [1, 8]))
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var achievementDetails: some View {
        RewardRibbon {
            VStack(spacing: 3) {
                Text(L10n.string("goal.share.card.date"))
                    .font(.caption.bold())
                Text(data.achievedAt, format: .dateTime.year().month().day())
                    .font(.headline)
            }
        }
    }

    private var brand: some View {
        HStack(spacing: 7) {
            Image(systemName: "seal.fill")
                .foregroundStyle(AppColors.sun)
            Text(L10n.string("home.title"))
                .font(.caption.bold())
                .foregroundStyle(cardInk.opacity(0.52))
        }
    }

    private var stampRows: [[StampEntry]] {
        stride(from: 0, to: data.entries.count, by: Self.columns).map { start in
            Array(data.entries[start..<min(start + Self.columns, data.entries.count)])
        }
    }
}

#Preview {
    GoalAchievementCard(
        data: GoalShareCardData(
            placement: GoalPlacement(goal: Goal(interval: 8, rewardName: "映画を観る"), targetCount: 8),
            entries: (0..<8).map { index in
                StampEntry(presetID: StampPreset.all[index % StampPreset.all.count].id)
            },
            rangeStart: 1,
            rangeEnd: 8,
            achievedAt: .now
        )
    )
    .padding()
}
