import SwiftUI

struct LaunchExperienceView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    private let sparkles: [(x: CGFloat, y: CGFloat, color: Color, delay: Double)] = [
        (-92, -76, AppColors.sun, 0.10),
        (96, -54, AppColors.coral, 0.16),
        (-104, 40, AppColors.sky, 0.22),
        (100, 70, AppColors.mint, 0.28)
    ]

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            ForEach(Array(sparkles.enumerated()), id: \.offset) { _, sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(sparkle.color)
                    .scaleEffect(isPresented ? 1 : 0.15)
                    .opacity(isPresented ? 1 : 0)
                    .offset(
                        x: isPresented ? sparkle.x : sparkle.x * 0.35,
                        y: isPresented ? sparkle.y : sparkle.y * 0.35
                    )
                    .rotationEffect(.degrees(isPresented ? 18 : -24))
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.48, dampingFraction: 0.58).delay(sparkle.delay),
                        value: isPresented
                    )
            }

            Image("LaunchMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 184, height: 184)
                .scaleEffect(isPresented ? 1 : 0.78)
                .rotationEffect(.degrees(reduceMotion || isPresented ? 0 : -7))
                .offset(y: reduceMotion || isPresented ? 0 : 18)
                .shadow(color: AppColors.ink.opacity(0.12), radius: 18, y: 10)
                .animation(
                    reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.62, dampingFraction: 0.58),
                    value: isPresented
                )

            VStack(spacing: 6) {
                Text("Gohobi Stickers")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.ink)

                Text(L10n.string("launch.tagline"))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.ink.opacity(0.62))
            }
            .offset(y: 150)
            .opacity(isPresented ? 1 : 0)
            .animation(.easeOut(duration: 0.35).delay(reduceMotion ? 0 : 0.2), value: isPresented)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.string("launch.accessibility"))
        .onAppear {
            isPresented = true

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 350 : 1_150))
                onFinished()
            }
        }
    }
}

#Preview {
    LaunchExperienceView {}
}
