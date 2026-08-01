import SwiftUI

struct ContentView: View {
    @Environment(StampStore.self) private var store
    @State private var isAddingStamp = false
    @State private var isShowingGoals = false
    @State private var isShowingAppearance = false
    @State private var editingEntry: StampEntry?

    private let routeOffsets: [CGFloat] = [-88, 0, 88, 0]

    private var routeEnd: Int {
        max(store.totalStampCount + 1, store.goalPlacements.last?.targetCount ?? 1, 1)
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
                                isNext: position == store.totalStampCount + 1,
                                offset: offset
                            ) {
                                if let entry {
                                    editingEntry = entry
                                } else if position == store.totalStampCount + 1 {
                                    isAddingStamp = true
                                }
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
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)

                if let celebration = store.celebration {
                    GoalCelebrationView(placement: celebration) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            store.clearCelebration()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.88)))
                    .zIndex(10)
                }
            }
            .navigationTitle(L10n.string("home.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingAppearance = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel(L10n.string("appearance.settings.accessibility"))
                }
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
            .sheet(isPresented: $isAddingStamp) {
                StampEditorView()
            }
            .sheet(isPresented: $isShowingAppearance) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $isShowingGoals) {
                GoalSettingsView()
            }
            .sheet(item: $editingEntry) { entry in
                StampEditorView(entry: entry)
            }
        }
        .tint(AppColors.coral)
        .sensoryFeedback(.success, trigger: store.celebration?.id)
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
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.surfaceHighlight, lineWidth: 2)
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

    private func entry(at position: Int) -> StampEntry? {
        let index = position - 1
        return store.entries.indices.contains(index) ? store.entries[index] : nil
    }

    private func goal(at position: Int) -> GoalPlacement? {
        store.goalPlacements.first { $0.targetCount == position }
    }
}

#Preview {
    ContentView()
        .environment(StampStore(fileURL: URL.temporaryDirectory.appending(path: "gohobi-preview.json")))
}
