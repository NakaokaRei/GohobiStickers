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
                                        presetID == preset.id ? AppColors.coral.opacity(0.13) : .white.opacity(0.72),
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
                            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

struct GoalSettingsView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingGoal = false
    @State private var editingGoal: Goal?

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
                        .onDelete(perform: store.deleteGoals)
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
        }
    }
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
