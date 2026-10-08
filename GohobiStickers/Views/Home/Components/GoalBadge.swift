import SwiftUI

struct GoalBadge: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let placement: GoalPlacement
    let isAchieved: Bool
    let onShare: () -> Void

    var body: some View {
        Group {
            if isAchieved {
                achievedBadge
            } else {
                upcomingBadge
            }
        }
        .padding(.horizontal, isAchieved ? 28 : 24)
        .padding(.vertical, isAchieved ? 30 : 22)
        .frame(maxWidth: isAchieved ? 360 : 280)
        .background {
            GoalCloud()
                .fill(AppColors.surface)
                .overlay {
                    GoalCloud()
                        .fill(AppColors.sun.opacity(isAchieved ? 0.12 : 0.04))
                }
                .overlay {
                    GoalCloud()
                        .strokeBorder(
                            isAchieved ? AppColors.sun.opacity(0.8) : AppColors.coral.opacity(0.3),
                            lineWidth: isAchieved ? 2.5 : 1.5
                        )
                }
                .shadow(color: AppColors.sun.opacity(isAchieved ? 0.16 : 0.06), radius: 10, y: 5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("goal-badge-\(placement.targetCount)")
    }

    private var achievedBadge: some View {
        VStack(spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    positionLabel
                    achievementLabel
                }
                VStack(spacing: 6) {
                    positionLabel
                    achievementLabel
                }
            }

            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppColors.sun)
                        .rotationEffect(.degrees(-12))
                        .accessibilityHidden(true)
                }
                Text(placement.goal.rewardName)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppColors.mint)
                        .accessibilityHidden(true)
                }
            }

            Button(action: onShare) {
                Label(L10n.string("goal.share.action"), systemImage: "square.and.arrow.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44)
                    .background(AppColors.surface, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("goal-share-button-\(placement.targetCount)")
        }
    }

    private var upcomingBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundStyle(AppColors.coral)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                positionLabel
                Text(placement.goal.rewardName)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var positionLabel: some View {
        Text(L10n.format("goal.position", placement.targetCount))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private var achievementLabel: some View {
        Label(L10n.string("goal.achieved"), systemImage: "checkmark")
            .font(.caption.bold())
            .foregroundStyle(AppColors.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppColors.sun.opacity(0.24), in: Capsule())
    }
}

/// A soft scalloped frame that stretches vertically with multiline rewards.
private struct GoalCloud: InsettableShape {
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        // Keep the lobes shallow when Dynamic Type makes the content tall.
        let capHeight = min(bounds.height, 220)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let verticalPosition: CGFloat
            if y < 0.3 {
                verticalPosition = y * capHeight
            } else if y > 0.7 {
                verticalPosition = bounds.height - (1 - y) * capHeight
            } else {
                verticalPosition = 0.3 * capHeight
                    + (y - 0.3) / 0.4 * (bounds.height - 0.6 * capHeight)
            }
            return CGPoint(x: bounds.minX + bounds.width * x, y: bounds.minY + verticalPosition)
        }
        var path = Path()
        path.move(to: point(0.08, 0.30))
        path.addCurve(to: point(0.23, 0.08), control1: point(-0.01, 0.12), control2: point(0.12, 0.01))
        path.addCurve(to: point(0.43, 0.06), control1: point(0.28, -0.02), control2: point(0.38, -0.01))
        path.addCurve(to: point(0.64, 0.06), control1: point(0.48, -0.02), control2: point(0.59, -0.02))
        path.addCurve(to: point(0.84, 0.11), control1: point(0.72, -0.02), control2: point(0.81, 0.01))
        path.addCurve(to: point(0.94, 0.34), control1: point(0.96, 0.06), control2: point(1.01, 0.22))
        path.addCurve(to: point(0.94, 0.65), control1: point(1.02, 0.40), control2: point(1.02, 0.57))
        path.addCurve(to: point(0.83, 0.90), control1: point(1.01, 0.81), control2: point(0.93, 0.96))
        path.addCurve(to: point(0.63, 0.94), control1: point(0.79, 1.01), control2: point(0.69, 1.02))
        path.addCurve(to: point(0.40, 0.94), control1: point(0.57, 1.02), control2: point(0.46, 1.02))
        path.addCurve(to: point(0.20, 0.91), control1: point(0.33, 1.02), control2: point(0.24, 1.00))
        path.addCurve(to: point(0.06, 0.68), control1: point(0.08, 0.97), control2: point(-0.01, 0.83))
        path.addCurve(to: point(0.08, 0.30), control1: point(-0.03, 0.59), control2: point(0.00, 0.39))
        path.closeSubpath()
        return path
    }
}
