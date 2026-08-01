import SwiftUI

struct StampEditorView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let entry: StampEntry?
    @State private var presetID: String
    @State private var comment: String
    @State private var isConfirmingDeletion = false

    init(entry: StampEntry? = nil) {
        self.entry = entry
        _presetID = State(initialValue: entry?.presetID ?? StampPreset.all[0].id)
        _comment = State(initialValue: entry?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.string("stamp.editor.choose"))
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 14) {
                            ForEach(StampPreset.all) { preset in
                                Button {
                                    withAnimation(.snappy) { presetID = preset.id }
                                } label: {
                                    VStack(spacing: 8) {
                                        StampArtwork(preset: preset, size: 68)
                                        Text(preset.name)
                                            .font(.caption.bold())
                                            .foregroundStyle(AppColors.ink)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        presetID == preset.id ? AppColors.coral.opacity(0.18) : AppColors.surface,
                                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(presetID == preset.id ? AppColors.coral : .clear, lineWidth: 3)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(preset.name)
                                .accessibilityAddTraits(presetID == preset.id ? .isSelected : [])
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.string("stamp.comment.title"))
                                .font(.headline)
                            Spacer()
                            Text(L10n.string("common.optional"))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }

                        TextEditor(text: $comment)
                            .frame(minHeight: 110)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                if comment.isEmpty {
                                    Text(L10n.string("stamp.comment.placeholder"))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    if let entry {
                        Text(entry.createdAt, format: .dateTime.year().month().day().hour().minute())
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Button(role: .destructive) {
                            isConfirmingDeletion = true
                        } label: {
                            Label(L10n.string("stamp.delete.button"), systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(L10n.string(entry == nil ? "stamp.editor.add.title" : "stamp.editor.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) { save() }
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog(
                L10n.string("stamp.delete.confirm.title"),
                isPresented: $isConfirmingDeletion,
                titleVisibility: .visible
            ) {
                Button(L10n.string("common.delete"), role: .destructive) {
                    if let entry { store.deleteEntry(id: entry.id) }
                    dismiss()
                }
            } message: {
                Text(L10n.string("stamp.delete.confirm.message"))
            }
        }
    }

    private func save() {
        if let entry {
            store.updateEntry(id: entry.id, presetID: presetID, comment: comment)
        } else {
            store.addEntry(presetID: presetID, comment: comment)
        }
        dismiss()
    }
}

struct AppearanceSettingsView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        L10n.string("appearance.picker.title"),
                        selection: Binding(
                            get: { store.appearance },
                            set: { store.setAppearance($0) }
                        )
                    ) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Label(appearance.localizedName, systemImage: appearance.symbolName)
                                .tag(appearance)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text(L10n.string("appearance.picker.title"))
                } footer: {
                    Text(L10n.string("appearance.footer"))
                }

                Section {
                    CloudSyncStatusRow(status: store.cloudSyncStatus)

                    Button {
                        Task { await store.synchronizeWithCloud() }
                    } label: {
                        Label(L10n.string("icloud.sync-now"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(store.cloudSyncStatus == .syncing)
                } header: {
                    Text(L10n.string("icloud.title"))
                } footer: {
                    Text(L10n.string("icloud.footer"))
                }
            }
            .navigationTitle(L10n.string("appearance.settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.close")) { dismiss() }
                }
            }
        }
        .preferredColorScheme(store.appearance.colorScheme)
        .animation(.easeInOut(duration: 0.2), value: store.appearance)
    }
}

private struct CloudSyncStatusRow: View {
    let status: CloudSyncStatus

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                if case .synced(let date) = status {
                    Text(
                        L10n.format(
                            "icloud.last-synced",
                            date.formatted(date: .omitted, time: .shortened)
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if case .failed(let message) = status {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(symbolColor)
        }
    }

    private var title: String {
        switch status {
        case .idle: L10n.string("icloud.status.idle")
        case .syncing: L10n.string("icloud.status.syncing")
        case .synced: L10n.string("icloud.status.synced")
        case .accountUnavailable: L10n.string("icloud.status.account-unavailable")
        case .failed: L10n.string("icloud.status.failed")
        }
    }

    private var symbolName: String {
        switch status {
        case .idle: "icloud"
        case .syncing: "icloud.and.arrow.up"
        case .synced: "checkmark.icloud.fill"
        case .accountUnavailable: "icloud.slash"
        case .failed: "exclamationmark.icloud.fill"
        }
    }

    private var symbolColor: Color {
        switch status {
        case .synced: AppColors.mint
        case .accountUnavailable, .failed: AppColors.coral
        case .idle, .syncing: .secondary
        }
    }
}

private extension AppAppearance {
    var localizedName: String {
        L10n.string("appearance.\(rawValue)")
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .dark: "moon.fill"
        case .light: "sun.max.fill"
        }
    }
}

struct GoalSettingsView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingGoal = false
    @State private var editingGoal: Goal?
    @State private var deletedGoals: GoalDeletion?

    var body: some View {
        NavigationStack {
            List {
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

                Section {
                    Button {
                        isAddingGoal = true
                    } label: {
                        Label(L10n.string("goal.add.button"), systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                    }
                }
            }
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
            .task(id: deletedGoals?.id) {
                guard let deletionID = deletedGoals?.id else { return }
                try? await Task.sleep(for: .seconds(6))
                guard !Task.isCancelled, deletedGoals?.id == deletionID else { return }
                withAnimation { deletedGoals = nil }
            }
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

struct GoalEditorView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let goal: Goal?
    @State private var interval: Int
    @State private var rewardName: String

    init(goal: Goal? = nil) {
        self.goal = goal
        _interval = State(initialValue: goal?.interval ?? 5)
        _rewardName = State(initialValue: goal?.rewardName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("goal.reward.section")) {
                    TextField(L10n.string("goal.reward.placeholder"), text: $rewardName)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Stepper(value: $interval, in: 1...999) {
                        HStack {
                            Text(L10n.string("goal.from.previous"))
                            Spacer()
                            Text(L10n.format("goal.count", interval))
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.coral)
                        }
                    }
                } footer: {
                    Text(L10n.string("goal.interval.footer"))
                }
            }
            .navigationTitle(L10n.string(goal == nil ? "goal.editor.add.title" : "goal.editor.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) { save() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func save() {
        if let goal {
            store.updateGoal(id: goal.id, interval: interval, rewardName: rewardName)
        } else {
            store.addGoal(interval: interval, rewardName: rewardName)
        }
        dismiss()
    }
}
