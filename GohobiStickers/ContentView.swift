import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(StampStore.self) private var store
    @State private var isAddingStamp = false
    @State private var isShowingGoals = false
    @State private var editingEntry: StampEntry?

    private let routeOffsets: [CGFloat] = [-88, 0, 88, 0]

    private var routeEnd: Int {
        max(store.totalStampCount, store.goalPlacements.last?.targetCount ?? 1, 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        totalHeader
                            .padding(.bottom, 28)

                        ForEach(1...routeEnd, id: \.self) { position in
                            let offset = routeOffsets[(position - 1) % routeOffsets.count]
                            let nextOffset = routeOffsets[position % routeOffsets.count]
                            let entry = entry(at: position)

                            RouteNode(
                                position: position,
                                entry: entry,
                                offset: offset
                            ) {
                                if let entry { editingEntry = entry }
                            }

                            if let placement = goal(at: position) {
                                GoalBadge(
                                    placement: placement,
                                    isAchieved: store.totalStampCount >= placement.targetCount
                                )
                                .padding(.vertical, 8)
                            }

                            if position < routeEnd {
                                RouteConnector(from: offset, to: nextOffset)
                            }
                        }

                        endOfRoute
                            .padding(.top, 24)
                            .padding(.bottom, 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(L10n.string("home.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingGoals = true
                    } label: {
                        Image(systemName: "flag.checkered")
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel(L10n.string("goal.settings.accessibility"))
                }
            }
            .safeAreaInset(edge: .bottom) {
                addStampButton
            }
            .sheet(isPresented: $isAddingStamp) {
                StampEditorView()
            }
            .sheet(isPresented: $isShowingGoals) {
                GoalSettingsView()
            }
            .sheet(item: $editingEntry) { entry in
                StampEditorView(entry: entry)
            }
        }
        .tint(AppColors.coral)
    }

    private var totalHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.sun.opacity(0.2))
                    .frame(width: 64, height: 64)
                Image(systemName: "seal.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppColors.sun)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("home.total.label"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(store.totalStampCount, format: .number)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                    Text(L10n.string("home.count.unit"))
                        .font(.title3.bold())
                }
                .foregroundStyle(AppColors.ink)
            }
            Spacer()
        }
        .padding(18)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white, lineWidth: 2)
        }
        .shadow(color: AppColors.ink.opacity(0.08), radius: 18, y: 8)
    }

    private var endOfRoute: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.pattern.checkered")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppColors.mint)
            Text(L10n.string(store.goals.isEmpty ? "home.goal.empty" : "home.goal.more"))
                .font(.headline)
                .foregroundStyle(AppColors.ink)
                .multilineTextAlignment(.center)
            Button(L10n.string("goal.settings.button")) {
                isShowingGoals = true
            }
            .buttonStyle(.bordered)
            .fontWeight(.bold)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppColors.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var addStampButton: some View {
        Button {
            isAddingStamp = true
        } label: {
            Label(L10n.string("stamp.add.button"), systemImage: "hand.tap.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(AppColors.coral, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppColors.coral.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func entry(at position: Int) -> StampEntry? {
        let index = position - 1
        return store.entries.indices.contains(index) ? store.entries[index] : nil
    }

    private func goal(at position: Int) -> GoalPlacement? {
        store.goalPlacements.first { $0.targetCount == position }
    }
}

private struct RouteNode: View {
    let position: Int
    let entry: StampEntry?
    let offset: CGFloat
    let action: () -> Void

    var body: some View {
        ZStack {
            if let entry {
                Button(action: action) {
                    StampArtwork(preset: .preset(for: entry.presetID), size: 78)
                        .overlay(alignment: .bottomTrailing) {
                            if !entry.comment.isEmpty {
                                Image(systemName: "text.bubble.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(7)
                                    .background(AppColors.mint, in: Circle())
                                    .offset(x: 5, y: 5)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.format("node.completed.accessibility", position, StampPreset.preset(for: entry.presetID).name))
            } else {
                ZStack {
                    Circle()
                        .fill(AppColors.emptyNode)
                    Circle()
                        .strokeBorder(.white.opacity(0.9), lineWidth: 5)
                    Text(position, format: .number)
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.ink.opacity(0.38))
                }
                .frame(width: 72, height: 72)
                .shadow(color: AppColors.ink.opacity(0.08), radius: 6, y: 4)
                .accessibilityLabel(L10n.format("node.empty.accessibility", position))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .offset(x: offset)
    }
}

private struct RouteConnector: View {
    let from: CGFloat
    let to: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2 + from, y: 0))
            path.addCurve(
                to: CGPoint(x: size.width / 2 + to, y: size.height),
                control1: CGPoint(x: size.width / 2 + from, y: size.height * 0.55),
                control2: CGPoint(x: size.width / 2 + to, y: size.height * 0.45)
            )
            context.stroke(
                path,
                with: .color(AppColors.route),
                style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [3, 18])
            )
        }
        .frame(height: 50)
        .accessibilityHidden(true)
    }
}

private struct GoalBadge: View {
    let placement: GoalPlacement
    let isAchieved: Bool

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
                Text(L10n.string("goal.achieved"))
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.mint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 300)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isAchieved ? AppColors.mint.opacity(0.45) : AppColors.coral.opacity(0.25), lineWidth: 2)
        }
        .shadow(color: AppColors.ink.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }
}

struct StampArtwork: View {
    let preset: StampPreset
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(fallbackColor.opacity(0.17))
            Circle()
                .strokeBorder(.white.opacity(0.95), lineWidth: max(3, size * 0.06))

            if let image = UIImage(named: preset.assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.1)
            } else {
                Image(systemName: preset.fallbackSymbol)
                    .font(.system(size: size * 0.43, weight: .bold))
                    .foregroundStyle(fallbackColor)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: fallbackColor.opacity(0.2), radius: 7, y: 4)
    }

    private var fallbackColor: Color {
        switch preset.fallbackColorName {
        case "sun": AppColors.sun
        case "flower": .pink
        case "crown": .orange
        case "heart": AppColors.coral
        case "sparkle": .purple
        default: AppColors.sky
        }
    }
}

enum AppColors {
    static let background = Color(red: 0.99, green: 0.96, blue: 0.89)
    static let ink = Color(red: 0.18, green: 0.20, blue: 0.24)
    static let coral = Color(red: 0.95, green: 0.35, blue: 0.30)
    static let mint = Color(red: 0.18, green: 0.63, blue: 0.52)
    static let sun = Color(red: 0.97, green: 0.67, blue: 0.16)
    static let sky = Color(red: 0.28, green: 0.62, blue: 0.88)
    static let route = Color(red: 0.76, green: 0.69, blue: 0.58).opacity(0.55)
    static let emptyNode = Color(red: 0.91, green: 0.87, blue: 0.78)
}

#Preview {
    ContentView()
        .environment(StampStore(fileURL: URL.temporaryDirectory.appending(path: "gohobi-preview.json")))
}
