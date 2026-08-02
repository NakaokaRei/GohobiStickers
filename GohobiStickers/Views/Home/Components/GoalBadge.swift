import SwiftUI

struct GoalBadge: View {
    let placement: GoalPlacement
    let isAchieved: Bool
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isAchieved ? "checkmark.seal.fill" : "gift.fill")
                .font(.title2)
                .foregroundStyle(isAchieved ? AppColors.mint : AppColors.coral)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.format("goal.position", placement.targetCount))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(placement.goal.rewardName)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
            }
            Spacer()
            if isAchieved {
                VStack(spacing: 4) {
                    Text(L10n.string("goal.achieved"))
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.mint)
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline.bold())
                            .foregroundStyle(AppColors.coral)
                            .frame(width: 38, height: 38)
                            .background(AppColors.coral.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.string("goal.share.action"))
                    .accessibilityIdentifier("goal-share-button-\(placement.targetCount)")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 300)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isAchieved ? AppColors.mint.opacity(0.45) : AppColors.coral.opacity(0.25), lineWidth: 2)
        }
        .shadow(color: AppColors.ink.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .contain)
    }
}
