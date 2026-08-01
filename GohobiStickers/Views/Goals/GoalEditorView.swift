import SwiftUI

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
