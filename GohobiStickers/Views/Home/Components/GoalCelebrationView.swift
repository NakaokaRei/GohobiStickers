import SwiftUI

struct GoalCelebrationView: View {
    let placement: GoalPlacement
    let share: () -> Void
    let dismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBursting = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            if !reduceMotion { particles }
            ScrollView {
                celebrationCard
                    .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.center)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.62)) {
                isBursting = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var particles: some View {
        ForEach(0..<20, id: \.self) { index in
            Image(systemName: index.isMultiple(of: 3) ? "star.fill" : "circle.fill")
                .font(.system(size: index.isMultiple(of: 3) ? 17 : 11, weight: .bold))
                .foregroundStyle(particleColor(at: index))
                .offset(
                    x: isBursting ? cos(angle(at: index)) * 175 : 0,
                    y: isBursting ? sin(angle(at: index)) * 300 : 10
                )
                .rotationEffect(.degrees(isBursting ? Double(index * 75) : 0))
                .opacity(isBursting ? 0 : 1)
                .animation(
                    .easeOut(duration: 1.25).delay(Double(index % 5) * 0.035),
                    value: isBursting
                )
        }
    }

    private var celebrationCard: some View {
        VStack(spacing: 18) {
            CelebrationCompanion(id: placement.id)

            VStack(spacing: 8) {
                Text(L10n.string("celebration.title"))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.ink)
                RewardRibbon {
                    Text(placement.goal.rewardName)
                        .font(.title2.bold())
                }
                Text(L10n.format("celebration.message", placement.targetCount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: share) {
                    Label(L10n.string("goal.share.celebration.action"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .font(.headline.bold())
                .accessibilityIdentifier("celebration-share-button")

                Button(L10n.string("celebration.dismiss"), action: dismiss)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityIdentifier("celebration-dismiss-button")
            }
        }
        .padding(28)
        .frame(maxWidth: 330)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .background(AppColors.background, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppColors.surfaceHighlight, lineWidth: 2)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.28), radius: 30, y: 14)
        .padding(24)
    }

    private func angle(at index: Int) -> CGFloat {
        CGFloat(index) / 20 * .pi * 2 - .pi / 2
    }

    private func particleColor(at index: Int) -> Color {
        switch index % 4 {
        case 0: AppColors.coral
        case 1: AppColors.sun
        case 2: AppColors.mint
        default: AppColors.sky
        }
    }
}
