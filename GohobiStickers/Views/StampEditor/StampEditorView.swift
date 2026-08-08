import PhotosUI
import SwiftUI

struct StampEditorView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let entry: StampEntry?
    private let onStampCreated: (UUID) -> Void
    @State private var presetID: String
    @State private var comment: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingImageData: Data?
    @State private var pendingImage: UIImage?
    @State private var isRemovingImage = false
    @State private var isLoadingImage = false
    @State private var imageErrorMessage: String?
    @State private var isConfirmingDeletion = false
    @State private var isPresentingImageViewer = false

    init(
        entry: StampEntry? = nil,
        onStampCreated: @escaping (UUID) -> Void = { _ in }
    ) {
        self.entry = entry
        self.onStampCreated = onStampCreated
        let initialPresetID = entry.map { StampPreset.preset(for: $0.presetID).id }
            ?? StampPreset.all[0].id
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
                        .disabled(isLoadingImage)
                        .accessibilityIdentifier("stamp-editor-save-button")
                }
            }
            .alert(
                L10n.string("stamp.delete.confirm.title"),
                isPresented: $isConfirmingDeletion
            ) {
                Button(L10n.string("common.delete"), role: .destructive) {
                    if let entry { store.deleteEntry(id: entry.id) }
                    dismiss()
                }
                Button(L10n.string("common.cancel"), role: .cancel) {}
            } message: {
                Text(L10n.string("stamp.delete.confirm.message"))
            }
            .alert(
                L10n.string("stamp.image.error.title"),
                isPresented: Binding(
                    get: { imageErrorMessage != nil },
                    set: { if !$0 { imageErrorMessage = nil } }
                )
            ) {
                Button(L10n.string("common.close"), role: .cancel) {}
            } message: {
                Text(imageErrorMessage ?? "")
            }
            .fullScreenCover(isPresented: $isPresentingImageViewer) {
                if let image = displayedImage {
                    AttachedPhotoViewer(image: image)
                }
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
                        presetID = preset.id
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
                        .animation(.snappy, value: presetID == preset.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                    .accessibilityAddTraits(presetID == preset.id ? .isSelected : [])
                }
            }
        }
    }

    private var displayedImage: UIImage? {
        if let pendingImage { return pendingImage }
        guard !isRemovingImage, let entry else { return nil }
        return store.image(for: entry)
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

            VStack(spacing: 0) {
                TextEditor(text: $comment)
                    .frame(minHeight: 110)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if comment.isEmpty {
                            Text(L10n.string("stamp.comment.placeholder"))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }

                Divider()
                    .padding(.horizontal, 12)

                imageAttachmentEditor
                    .padding(12)
                    .onChange(of: selectedPhotoItem) { _, item in
                        guard let item else { return }
                        Task { await loadPhoto(from: item) }
                    }
            }
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    @ViewBuilder
    private var imageAttachmentEditor: some View {
        if let image = displayedImage {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    isPresentingImageViewer = true
                } label: {
                    AttachedPhotoThumbnail(
                        image: image,
                        maximumSize: CGSize(width: 108, height: 132)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(.black.opacity(0.58), in: Circle())
                            .padding(6)
                    }
                    .overlay {
                        if isLoadingImage {
                            ProgressView()
                                .tint(.primary)
                                .padding(14)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoadingImage)
                .accessibilityLabel(L10n.string("stamp.image.view"))
                .accessibilityHint(L10n.string("stamp.image.view.hint"))
                .accessibilityIdentifier("stamp-image-preview")

                VStack(alignment: .leading, spacing: 4) {
                    Label(
                        L10n.string("stamp.image.preview.accessibility"),
                        systemImage: "paperclip"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.ink)

                    Text(L10n.string("stamp.image.view.hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    HStack(spacing: 8) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text(L10n.string("stamp.image.change"))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(AppColors.coral)
                        .disabled(isLoadingImage)
                        .accessibilityIdentifier("stamp-image-picker-button")

                        Button(role: .destructive) {
                            pendingImageData = nil
                            pendingImage = nil
                            isRemovingImage = true
                            selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isLoadingImage)
                        .accessibilityLabel(L10n.string("stamp.image.remove"))
                        .accessibilityIdentifier("stamp-image-remove-button")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColors.background.opacity(0.55),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.ink.opacity(0.07), lineWidth: 1)
            }
        } else if isLoadingImage {
            HStack(spacing: 12) {
                ProgressView()
                Text(L10n.string("stamp.image.loading"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .accessibilityIdentifier("stamp-image-loading")
        } else {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppColors.coral)
                        .frame(width: 42, height: 42)
                        .background(AppColors.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string("stamp.image.add"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.ink)
                        Text(L10n.string("stamp.image.attachment.hint"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .contentShape(Rectangle())
                .background(
                    AppColors.coral.opacity(0.055),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            AppColors.coral.opacity(0.35),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stamp-image-picker-button")
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

    private func loadPhoto(from item: PhotosPickerItem) async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        do {
            guard let sourceData = try await item.loadTransferable(type: Data.self) else {
                throw StampImageStoreError.invalidImage
            }
            let normalizedData = try await store.prepareImageDataInBackground(sourceData)
            try Task.checkCancellation()
            guard selectedPhotoItem == item else { return }
            guard let previewImage = UIImage(data: normalizedData) else {
                throw StampImageStoreError.invalidImage
            }
            pendingImageData = normalizedData
            pendingImage = previewImage
            isRemovingImage = false
        } catch {
            selectedPhotoItem = nil
            imageErrorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            if let entry {
                let imageChange: StampImageChange
                if let pendingImageData {
                    imageChange = .replace(pendingImageData)
                } else if isRemovingImage {
                    imageChange = .remove
                } else {
                    imageChange = .unchanged
                }
                try store.updateEntry(
                    id: entry.id,
                    presetID: presetID,
                    comment: comment,
                    imageChange: imageChange
                )
            } else {
                let entryID = try store.addEntry(
                    presetID: presetID,
                    comment: comment,
                    imageData: pendingImageData
                )
                onStampCreated(entryID)
            }
            dismiss()
        } catch {
            imageErrorMessage = error.localizedDescription
        }
    }
}
