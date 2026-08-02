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
        let savedPresetID = entry?.presetID
        let initialPresetID = savedPresetID.flatMap { id in
            StampPreset.all.contains { $0.id == id } ? id : nil
        } ?? StampPreset.all[0].id
        _presetID = State(initialValue: initialPresetID)
        _comment = State(initialValue: entry?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    presetPicker
                    commentEditor

                    if let entry {
                        existingEntryActions(entry)
                    }
                }
                .padding(20)
            }
            .accessibilityIdentifier("stamp-editor-screen")
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(L10n.string(entry == nil ? "stamp.editor.add.title" : "stamp.editor.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                        .accessibilityIdentifier("stamp-editor-cancel-button")
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

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("stamp.editor.choose"))
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: StampMetrics.pickerMinimumColumnWidth))],
                spacing: 14
            ) {
                ForEach(StampPreset.all) { preset in
                    Button {
                        withAnimation(.snappy) { presetID = preset.id }
                    } label: {
                        VStack(spacing: 8) {
                            StampArtwork(preset: preset, size: StampMetrics.pickerArtworkSize)
                            Text(preset.name)
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.ink)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, StampMetrics.pickerCardVerticalPadding)
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
    }

    private var commentEditor: some View {
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
    }

    private func existingEntryActions(_ entry: StampEntry) -> some View {
        Group {
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

    private func save() {
        if let entry {
            store.updateEntry(id: entry.id, presetID: presetID, comment: comment)
        } else {
            store.addEntry(presetID: presetID, comment: comment)
        }
        dismiss()
    }
}
