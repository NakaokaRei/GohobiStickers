import SwiftUI

struct RoadEditorView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let road: RewardRoad?
    @State private var name: String

    init(road: RewardRoad? = nil) {
        self.road = road
        _name = State(initialValue: road?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("road.editor.name.section")) {
                    TextField(L10n.string("road.editor.name.placeholder"), text: $name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .accessibilityIdentifier("road-editor-name-field")
                }
            }
            .accessibilityIdentifier("road-editor-screen")
            .navigationTitle(
                L10n.string(road == nil ? "road.editor.add.title" : "road.editor.edit.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save"), action: save)
                        .fontWeight(.bold)
                        .disabled(trimmedName.isEmpty)
                        .accessibilityIdentifier("road-editor-save-button")
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        if let road {
            store.updateRoad(id: road.id, name: trimmedName)
        } else {
            store.addRoad(name: trimmedName)
        }
        dismiss()
    }
}

#Preview {
    RoadEditorView()
        .environment(
            StampStore(fileURL: URL.temporaryDirectory.appending(path: "road-editor-preview.json"))
        )
}
