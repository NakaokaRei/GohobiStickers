import SwiftUI

struct GoalSettingsView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingGoal = false
    @State private var editingGoal: Goal?
    @State private var deletedGoals: GoalDeletion?

    var body: some View {
        NavigationStack {
            List {
                goalsSection
                addGoalSection
            }
            .accessibilityIdentifier("goal-settings-screen")
            .navigationTitle(L10n.string("goal.settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.close")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isAddingGoal) {
                GoalEditorView()
            }
            .sheet(item: $editingGoal) { goal in
                GoalEditorView(goal: goal)
            }
            .safeAreaInset(edge: .bottom) {
                undoBanner
            }
            .task(id: deletedGoals?.id) {
                guard let deletionID = deletedGoals?.id else { return }
                try? await Task.sleep(for: .seconds(6))
                guard !Task.isCancelled, deletedGoals?.id == deletionID else { return }
                withAnimation { deletedGoals = nil }
            }
        }
    }

    private var goalsSection: some View {
        Section {
            if store.goals.isEmpty {
                ContentUnavailableView(
                    L10n.string("goal.empty.title"),
                    systemImage: "flag.checkered",
                    description: Text(L10n.string("goal.empty.description"))
                )
            } else {
                ForEach(store.goalPlacements) { placement in
                    Button {
                        editingGoal = placement.goal
                    } label: {
                        GoalSettingsRow(placement: placement)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteGoals)
                .onMove(perform: store.moveGoals)
            }
        } header: {
            Text(L10n.string("goal.settings.order"))
        } footer: {
            Text(L10n.string("goal.settings.footer"))
        }
    }

    private var addGoalSection: some View {
        Section {
            Button {
                isAddingGoal = true
            } label: {
                Label(L10n.string("goal.add.button"), systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private var undoBanner: some View {
        if let deletedGoals {
            HStack(spacing: 16) {
                Text(L10n.string("goal.delete.message"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                Spacer()
                Button(L10n.string("common.undo")) {
                    undoDeletion(deletedGoals)
                }
                .font(.subheadline.bold())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.surfaceHighlight, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func deleteGoals(at offsets: IndexSet) {
        let items = offsets.sorted().compactMap { offset -> GoalDeletion.Item? in
            guard store.goals.indices.contains(offset) else { return nil }
            return GoalDeletion.Item(offset: offset, goal: store.goals[offset])
        }
        guard !items.isEmpty else { return }

        store.deleteGoals(at: offsets)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            deletedGoals = GoalDeletion(items: items)
        }
    }

    private func undoDeletion(_ deletion: GoalDeletion) {
        store.restoreGoals(deletion.items.map { (offset: $0.offset, goal: $0.goal) })
        withAnimation { deletedGoals = nil }
    }
}

private struct GoalDeletion: Identifiable {
    struct Item {
        let offset: Int
        let goal: Goal
    }

    let id = UUID()
    let items: [Item]
}

private struct GoalSettingsRow: View {
    let placement: GoalPlacement

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(AppColors.coral.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: "gift.fill")
                    .foregroundStyle(AppColors.coral)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(placement.goal.rewardName)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                Text(L10n.format("goal.interval.summary", placement.goal.interval))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(L10n.format("goal.cumulative", placement.targetCount))
                .font(.caption.bold())
                .foregroundStyle(AppColors.mint)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
