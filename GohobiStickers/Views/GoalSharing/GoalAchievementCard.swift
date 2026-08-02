import SwiftUI

struct GoalAchievementCard: View {
    static let width: CGFloat = 360
    static let cornerRadius: CGFloat = 34
    private static let columns = 3
    private static let stampSize: CGFloat = 82

    let data: GoalShareCardData

    private let cardBackground = Color(red: 0.99, green: 0.96, blue: 0.89)
    private let cardInk = Color(red: 0.18, green: 0.20, blue: 0.24)
    private let cardSurface = Color.white.opacity(0.88)

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
        .shadow(color: cardInk.opacity(0.15), radius: 18, y: 10)
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("goal-achievement-card")
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.sun.opacity(0.2))
                    .frame(width: 82, height: 82)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 39, weight: .bold))
                    .foregroundStyle(AppColors.sun)
            }

            Text(L10n.string("goal.share.card.title"))
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(cardInk)

            Text(data.placement.goal.rewardName)
                .font(.title2.bold())
                .foregroundStyle(AppColors.coral)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.format("goal.share.card.range", data.rangeStart, data.rangeEnd))
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.mint)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.mint.opacity(0.12), in: Capsule())
        }
    }

    private var stampGrid: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 12) {
            ForEach(stampRows.indices, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<Self.columns, id: \.self) { columnIndex in
                        let entryIndex = rowIndex * Self.columns + columnIndex
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
        .padding(14)
        .background(cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white, lineWidth: 2)
        }
    }

    private var achievementDetails: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.headline)
                .foregroundStyle(AppColors.coral)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("goal.share.card.date"))
                    .font(.caption.bold())
                    .foregroundStyle(cardInk.opacity(0.55))
                Text(data.achievedAt, format: .dateTime.year().month().day())
                    .font(.headline)
                    .foregroundStyle(cardInk)
            }
            Spacer()
        }
        .padding(16)
        .background(cardSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
