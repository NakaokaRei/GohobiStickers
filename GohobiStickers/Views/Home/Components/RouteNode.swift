import SwiftUI

struct RouteNode: View {
    @Environment(StampStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let praiseKeys = [
        "stamp.praise.amazing",
        "stamp.praise.lovely",
        "stamp.praise.you-did-it",
        "stamp.praise.great-job"
    ]

    let position: Int
    let entry: StampEntry?
    let isNext: Bool
    let offset: CGFloat
    let shouldHidePlacement: Bool
    let shouldAnimatePlacement: Bool
    let action: () -> Void

    @State private var stampScale: CGFloat = 1
    @State private var stampRotation = 0.0
    @State private var stampOffsetX: CGFloat = 0
    @State private var stampOffsetY: CGFloat = 0
    @State private var stampOpacity = 1.0
    @State private var impactRingScale: CGFloat = 0.72
    @State private var impactRingOpacity = 0.0
    @State private var glowScale: CGFloat = 0.78
    @State private var glowOpacity = 0.0
    @State private var sparkleScale: CGFloat = 0.6
    @State private var sparkleOpacity = 0.0
    @State private var placementGuideOpacity = 1.0
    @State private var praiseText = ""
    @State private var praiseScale: CGFloat = 0.72
    @State private var praiseOffsetY: CGFloat = 8
    @State private var praiseOpacity = 0.0
    @State private var placementImpactCount = 0
    @State private var placementAnimationStarted = false

    var body: some View {
        ZStack {
            if let entry {
                completedNode(entry)
            } else {
                emptyNode
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: StampMetrics.routeNodeHeight)
        .offset(x: offset)
    }

    private func completedNode(_ entry: StampEntry) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(
                        AppColors.completedRoute.opacity(0.72),
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [6, 7]
                        )
                    )
                    .frame(
                        width: StampMetrics.routeArtworkSize,
                        height: StampMetrics.routeArtworkSize
                    )
                    .opacity(placementGuideIsVisible ? placementGuideOpacity : 0)

                Circle()
                    .fill(AppColors.sun)
                    .frame(
                        width: StampMetrics.routeArtworkSize + 8,
                        height: StampMetrics.routeArtworkSize + 8
                    )
                    .blur(radius: 12)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)

                Circle()
                    .stroke(AppColors.sun, lineWidth: 5)
                    .frame(
                        width: StampMetrics.routeArtworkSize + 14,
                        height: StampMetrics.routeArtworkSize + 14
                    )
                    .scaleEffect(impactRingScale)
                    .opacity(impactRingOpacity)

                StampArtwork(
                    preset: .preset(for: entry.presetID),
                    size: StampMetrics.routeArtworkSize
                )
                .overlay(alignment: .bottomTrailing) {
                    HStack(spacing: 3) {
                        if entry.imageRevision != nil {
                            Image(systemName: "photo.fill")
                                .accessibilityLabel(L10n.string("stamp.image.badge.accessibility"))
                                .accessibilityIdentifier("stamp-image-badge-\(position)")
                        }
                        if !entry.comment.isEmpty {
                            Image(systemName: "text.bubble.fill")
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(AppColors.mint, in: Capsule())
                    .offset(x: 5, y: 5)
                    .opacity(entry.imageRevision != nil || !entry.comment.isEmpty ? 1 : 0)
                }
                .scaleEffect(renderedStampScale)
                .rotationEffect(.degrees(renderedStampRotation))
                .offset(x: renderedStampOffsetX, y: renderedStampOffsetY)
                .opacity(renderedStampOpacity)

                Image(systemName: "sparkles")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(AppColors.sun)
                    .scaleEffect(sparkleScale)
                    .offset(x: StampMetrics.routeArtworkSize * 0.46, y: -StampMetrics.routeArtworkSize * 0.45)
                    .opacity(sparkleOpacity)

                Text(praiseText)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.coral)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(AppColors.surface, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(AppColors.sun.opacity(0.5), lineWidth: 2)
                    }
                    .shadow(color: AppColors.sun.opacity(0.28), radius: 8, y: 3)
                    .scaleEffect(praiseScale)
                    .offset(y: -StampMetrics.routeArtworkSize / 2 - 21 + praiseOffsetY)
                    .opacity(praiseOpacity)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(
            .impact(weight: .medium, intensity: 1),
            trigger: placementImpactCount
        )
        .task(id: shouldAnimatePlacement) {
            guard shouldAnimatePlacement else { return }
            await playPlacementAnimation()
        }
        .accessibilityLabel(
            L10n.format(
                "node.completed.accessibility",
                position,
                StampPreset.preset(for: entry.presetID).name
            )
        )
        .accessibilityIdentifier("stamp-node-\(position)")
        .contextMenu {
            Button(action: action) {
                Label(L10n.string("node.quick-look.edit"), systemImage: "pencil")
            }
            .accessibilityIdentifier("stamp-node-quick-look-edit-button")
        } preview: {
            StampNodeQuickLook(entry: entry, image: store.image(for: entry))
        }
    }

    private var isWaitingForPlacementAnimation: Bool {
        shouldAnimatePlacement && !placementAnimationStarted
    }

    private var placementGuideIsVisible: Bool {
        shouldHidePlacement || shouldAnimatePlacement
    }

    private var renderedStampScale: CGFloat {
        isWaitingForPlacementAnimation && !reduceMotion ? 0.88 : stampScale
    }

    private var renderedStampRotation: Double {
        isWaitingForPlacementAnimation && !reduceMotion ? -8 : stampRotation
    }

    private var renderedStampOffsetX: CGFloat {
        isWaitingForPlacementAnimation && !reduceMotion ? 12 : stampOffsetX
    }

    private var renderedStampOffsetY: CGFloat {
        isWaitingForPlacementAnimation && !reduceMotion ? -14 : stampOffsetY
    }

    private var renderedStampOpacity: Double {
        shouldHidePlacement || isWaitingForPlacementAnimation ? 0 : stampOpacity
    }

    @MainActor
    private func playPlacementAnimation() async {
        guard !reduceMotion else {
            stampOpacity = 0
            placementAnimationStarted = true
            await Task.yield()
            withAnimation(.easeOut(duration: 0.2)) {
                stampOpacity = 1
                placementGuideOpacity = 0
            }
            return
        }

        stampScale = 0.88
        stampRotation = -8
        stampOffsetX = 12
        stampOffsetY = -14
        stampOpacity = 0
        impactRingScale = 0.72
        glowScale = 0.78
        sparkleScale = 0.6
        placementGuideOpacity = 1
        praiseText = L10n.string(
            Self.praiseKeys.randomElement() ?? "stamp.praise.you-did-it"
        )
        praiseScale = 0.72
        praiseOffsetY = 8
        praiseOpacity = 0
        placementAnimationStarted = true

        await Task.yield()

        withAnimation(.easeInOut(duration: 0.22)) {
            stampScale = 0.96
            stampRotation = -1
            stampOffsetX = 2
            stampOffsetY = -2
            stampOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(220))
        guard !Task.isCancelled else { return }

        placementImpactCount += 1
        impactRingOpacity = 0.58
        glowOpacity = 0.32
        sparkleOpacity = 0.95
        praiseOpacity = 1

        withAnimation(.easeOut(duration: 0.12)) {
            placementGuideOpacity = 0
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.62)) {
            stampScale = 1
            stampRotation = 0
            stampOffsetX = 0
            stampOffsetY = 0
            impactRingScale = 1.32
            glowScale = 1.18
            sparkleScale = 1
            praiseScale = 1
            praiseOffsetY = 0
        }

        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.38)) {
            impactRingOpacity = 0
            glowOpacity = 0
            sparkleOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            praiseScale = 0.96
            praiseOffsetY = -7
            praiseOpacity = 0
        }
    }

    private var emptyNode: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isNext ? AppColors.coral.opacity(0.16) : AppColors.emptyNode)
                Circle()
                    .strokeBorder(isNext ? AppColors.coral : AppColors.surfaceHighlight, lineWidth: 5)
                if isNext {
                    Image(systemName: "hand.tap.fill")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.coral)
                } else {
                    Text(position, format: .number)
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.ink.opacity(0.48))
                }
            }
            .frame(
                width: StampMetrics.routeEmptyNodeSize,
                height: StampMetrics.routeEmptyNodeSize
            )
            .shadow(color: AppColors.ink.opacity(0.08), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isNext)
        .accessibilityLabel(
            isNext
                ? L10n.format("node.next.accessibility", position)
                : L10n.format("node.empty.accessibility", position)
        )
        .accessibilityIdentifier(isNext ? "next-stamp-node" : "future-stamp-node-\(position)")
    }
}
