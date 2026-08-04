import SwiftUI

struct ContentView: View {
    @Environment(StampStore.self) private var store
    @State private var isAddingStamp = false
    @State private var isAddingRoad = false
    @State private var isShowingRoadSettings = false
    @State private var isShowingGoals = false
    @State private var isShowingAppearance = false
    @State private var editingEntry: StampEntry?
    @State private var shareCardData: GoalShareCardData?
    @State private var didHandleUITestDeepLink = false
    @State private var pendingStampAnimationID: UUID?
    @State private var animatingStampID: UUID?
    @State private var isCurrentPositionVisible = true

    private let routeOffsets: [CGFloat] = [-88, 0, 88, 0]

    private var routeEnd: Int {
        max(store.totalStampCount + 1, store.goalPlacements.last?.targetCount ?? 1, 1)
    }

    private var currentPosition: Int {
        store.totalStampCount + 1
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ZStack {
                    AppColors.background.ignoresSafeArea()

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            totalHeader
                                .id(0)
                                .padding(.bottom, 28)

                            ForEach(1...routeEnd, id: \.self) { position in
                                let offset = routeOffsets[(position - 1) % routeOffsets.count]
                                let nextOffset = routeOffsets[position % routeOffsets.count]
                                let entry = entry(at: position)

                                RouteNode(
                                    position: position,
                                    entry: entry,
                                    isNext: position == currentPosition,
                                    offset: offset,
                                    shouldHidePlacement: entry?.id == pendingStampAnimationID,
                                    shouldAnimatePlacement: entry?.id == animatingStampID
                                ) {
                                    if let entry {
                                        editingEntry = entry
                                    } else if position == currentPosition {
                                        isAddingStamp = true
                                    }
                                }
                                .id(position)

                                if let placement = goal(at: position) {
                                    GoalBadge(
                                        placement: placement,
                                        isAchieved: store.totalStampCount >= placement.targetCount,
                                        onShare: { presentShareCard(for: placement) }
                                    )
                                    .padding(.vertical, 8)
                                }

                                if position < routeEnd {
                                    RouteConnector(
                                        from: offset,
                                        to: nextOffset,
                                        isCompleted: position < store.totalStampCount
                                    )
                                }
                            }

                            endOfRoute
                                .padding(.top, 24)
                                .padding(.bottom, 40)
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                    .scrollIndicators(.hidden)
                    .onScrollTargetVisibilityChange(idType: Int.self, threshold: 0.4) { positions in
                        let isVisible = positions.contains(currentPosition)
                        guard isCurrentPositionVisible != isVisible else { return }
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            isCurrentPositionVisible = isVisible
                        }
                    }

                    if let celebration = store.celebration {
                        GoalCelebrationView(
                            placement: celebration,
                            share: { presentShareCard(for: celebration) }
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                store.clearCelebration()
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.88)))
                        .zIndex(10)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    currentPositionButton(scrollProxy)
                }
                .onChange(of: currentPosition) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        isCurrentPositionVisible = false
                    }
                }
                .onChange(of: store.selectedRoadID) {
                    var transaction = Transaction(animation: nil)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        scrollProxy.scrollTo(0, anchor: .top)
                        isCurrentPositionVisible = true
                    }
                }
            }
            .navigationTitle(store.selectedRoad.name)
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
                ToolbarItem(placement: .principal) {
                    roadPicker
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingGoals = true
                    } label: {
                        Image(systemName: "flag.checkered")
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel(L10n.string("goal.settings.accessibility"))
                    .accessibilityIdentifier("goal-settings-button")
                }
            }
            .sheet(isPresented: $isAddingStamp, onDismiss: animatePendingStamp) {
                StampEditorView { entryID in
                    pendingStampAnimationID = entryID
                }
            }
            .sheet(isPresented: $isAddingRoad) {
                RoadEditorView()
            }
            .sheet(isPresented: $isShowingRoadSettings) {
                RoadSettingsView()
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
            .sheet(item: $shareCardData) { data in
                GoalShareSheet(data: data)
                    .presentationDetents([.large])
            }
            .onChange(of: store.selectedRoadID) {
                pendingStampAnimationID = nil
                animatingStampID = nil
                editingEntry = nil
                shareCardData = nil
                isCurrentPositionVisible = true
            }
        }
        .tint(AppColors.coral)
        .sensoryFeedback(.success, trigger: store.celebration?.id)
        .onOpenURL { url in
            guard GohobiDeepLink.route(for: url) == .addStamp else { return }
            presentNewStampEditor()
        }
        .task {
            #if DEBUG
            guard
                !didHandleUITestDeepLink,
                ProcessInfo.processInfo.arguments.contains("--open-stamp-editor")
            else { return }
            didHandleUITestDeepLink = true
            presentNewStampEditor()
            #endif
        }
    }

    private var roadPicker: some View {
        Menu {
            ForEach(store.roads) { road in
                Button {
                    selectRoad(id: road.id)
                } label: {
                    Label(
                        road.name,
                        systemImage: road.id == store.selectedRoadID ? "checkmark" : "map"
                    )
                }
            }

            Divider()

            Button {
                isAddingRoad = true
            } label: {
                Label(L10n.string("road.add.button"), systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier("road-picker-add-button")

            Button {
                isShowingRoadSettings = true
            } label: {
                Label(L10n.string("road.settings.button"), systemImage: "slider.horizontal.3")
            }
            .accessibilityIdentifier("road-picker-settings-button")
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    // Keep the title's layout width stable while the Menu dismisses.
                    // Otherwise the toolbar can briefly clip the leading character
                    // when switching from a shorter road name to a longer one.
                    ForEach(store.roads) { road in
                        Text(road.name)
                            .hidden()
                            .accessibilityHidden(true)
                    }

                    Text(store.selectedRoad.name)
                }
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: 220)
                Image(systemName: "chevron.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppColors.coral)
            }
            .font(.headline.bold())
            .foregroundStyle(AppColors.ink)
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .accessibilityLabel(
            L10n.format("road.picker.accessibility", store.selectedRoad.name)
        )
        .accessibilityIdentifier("road-picker-button")
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
        .accessibilityIdentifier("total-stamp-header")
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

    @ViewBuilder
    private func currentPositionButton(_ scrollProxy: ScrollViewProxy) -> some View {
        if !isCurrentPositionVisible && store.celebration == nil {
            Button {
                withAnimation(.easeInOut(duration: 0.5)) {
                    scrollProxy.scrollTo(currentPosition, anchor: .center)
                }
            } label: {
                Label(
                    L10n.string("route.current-position.button"),
                    systemImage: "location.fill"
                )
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.coral)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surface, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AppColors.surfaceHighlight, lineWidth: 2)
                }
                .shadow(color: AppColors.ink.opacity(0.14), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("current-position-button")
            .padding(.trailing, 18)
            .padding(.bottom, 18)
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.82, anchor: .trailing).combined(with: .opacity),
                    removal: .scale(scale: 0.92, anchor: .trailing).combined(with: .opacity)
                )
            )
        }
    }

    private func entry(at position: Int) -> StampEntry? {
        let index = position - 1
        return store.entries.indices.contains(index) ? store.entries[index] : nil
    }

    private func goal(at position: Int) -> GoalPlacement? {
        store.goalPlacements.first { $0.targetCount == position }
    }

    private func selectRoad(id: UUID) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            store.selectRoad(id: id)
        }
    }

    private func presentShareCard(for placement: GoalPlacement) {
        shareCardData = store.goalShareCardData(for: placement)
    }

    private func animatePendingStamp() {
        guard let entryID = pendingStampAnimationID else { return }
        pendingStampAnimationID = nil
        animatingStampID = entryID

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_100))
            guard animatingStampID == entryID else { return }
            animatingStampID = nil
        }
    }

    private func presentNewStampEditor() {
        store.clearCelebration()
        isAddingStamp = false
        isAddingRoad = false
        isShowingRoadSettings = false
        isShowingGoals = false
        isShowingAppearance = false
        editingEntry = nil
        shareCardData = nil

        Task { @MainActor in
            await Task.yield()
            isAddingStamp = true
        }
    }
}

#Preview {
    ContentView()
        .environment(StampStore(fileURL: URL.temporaryDirectory.appending(path: "gohobi-preview.json")))
}
