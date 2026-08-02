import SwiftUI

struct GoalShareSheet: View {
    let data: GoalShareCardData

    @Environment(\.dismiss) private var dismiss
    @State private var renderedCard: RenderedGoalShareCard?
    @State private var didFail = false
    @State private var isShowingSystemShare = false

    var body: some View {
        NavigationStack {
            Group {
                if let renderedCard {
                    preview(renderedCard)
                } else if didFail {
                    failureView
                } else {
                    loadingView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(L10n.string("goal.share.preview.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.close")) { dismiss() }
                        .accessibilityIdentifier("goal-share-close-button")
                }
            }
            .safeAreaInset(edge: .bottom) {
                shareAction
            }
        }
        .accessibilityIdentifier("goal-share-preview-screen")
        .task(id: data.id) {
            await generateImage()
        }
        .sheet(isPresented: $isShowingSystemShare) {
            if let renderedCard {
                SystemImageShareSheet(image: renderedCard.image)
                    .ignoresSafeArea()
            }
        }
    }

    private func preview(_ renderedCard: RenderedGoalShareCard) -> some View {
        ScrollView {
            Image(uiImage: renderedCard.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: GoalAchievementCard.width)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: GoalAchievementCard.cornerRadius,
                        style: .continuous
                    )
                )
                .padding(.horizontal, 18)
                .padding(.vertical, 24)
                .accessibilityLabel(L10n.string("goal.share.preview.image.accessibility"))
        }
        .scrollIndicators(.hidden)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(L10n.string("goal.share.rendering"))
                .font(.headline)
                .foregroundStyle(AppColors.ink)
        }
        .accessibilityIdentifier("goal-share-loading")
    }

    private var failureView: some View {
        ContentUnavailableView {
            Label(L10n.string("goal.share.error.title"), systemImage: "photo.badge.exclamationmark")
        } description: {
            Text(L10n.string("goal.share.error.message"))
        } actions: {
            Button(L10n.string("goal.share.retry")) {
                Task { await generateImage() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("goal-share-retry-button")
        }
    }

    @ViewBuilder
    private var shareAction: some View {
        if let renderedCard {
            Button {
                isShowingSystemShare = true
            } label: {
                shareButtonLabel(
                    title: L10n.string("goal.share.action"),
                    systemImage: "square.and.arrow.up",
                    background: AnyShapeStyle(AppColors.coral)
                )
            }
            .accessibilityIdentifier("goal-share-action-button")
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func shareButtonLabel(
        title: String,
        systemImage: String,
        background: AnyShapeStyle
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func generateImage() async {
        didFail = false
        renderedCard = nil
        await Task.yield()

        if let card = GoalShareCardRenderer.render(data) {
            renderedCard = card
        } else {
            didFail = true
        }
    }
}

#Preview {
    GoalShareSheet(
        data: GoalShareCardData(
            placement: GoalPlacement(goal: Goal(interval: 5, rewardName: "ケーキ"), targetCount: 5),
            entries: (0..<5).map { index in
                StampEntry(presetID: StampPreset.all[index % StampPreset.all.count].id)
            },
            rangeStart: 1,
            rangeEnd: 5,
            achievedAt: .now
        )
    )
}
