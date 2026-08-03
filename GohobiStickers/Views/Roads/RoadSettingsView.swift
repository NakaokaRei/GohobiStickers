import SwiftUI

struct RoadSettingsView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingRoad = false
    @State private var editingRoad: RewardRoad?
    @State private var roadPendingDeletion: RewardRoad?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.roads) { road in
                        Button {
                            store.selectRoad(id: road.id)
                            dismiss()
                        } label: {
                            RoadSettingsRow(
                                road: road,
                                isSelected: road.id == store.selectedRoadID
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("road-row-\(road.id.uuidString)")
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingRoad = road
                            } label: {
                                Label(L10n.string("road.rename.button"), systemImage: "pencil")
                            }
                            .tint(AppColors.sky)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if store.roads.count > 1 {
                                Button(role: .destructive) {
                                    roadPendingDeletion = road
                                } label: {
                                    Label(L10n.string("common.delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                } footer: {
                    Text(L10n.string("road.settings.footer"))
                }
            }
            .accessibilityIdentifier("road-settings-screen")
            .navigationTitle(L10n.string("road.settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.close")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingRoad = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(L10n.string("road.add.button"))
                    .accessibilityIdentifier("road-settings-add-button")
                }
            }
            .sheet(isPresented: $isAddingRoad) {
                RoadEditorView()
            }
            .sheet(item: $editingRoad) { road in
                RoadEditorView(road: road)
            }
            .alert(
                L10n.string("road.delete.confirm.title"),
                isPresented: Binding(
                    get: { roadPendingDeletion != nil },
                    set: { if !$0 { roadPendingDeletion = nil } }
                ),
                presenting: roadPendingDeletion
            ) { road in
                Button(L10n.string("common.delete"), role: .destructive) {
                    store.deleteRoad(id: road.id)
                    roadPendingDeletion = nil
                }
                Button(L10n.string("common.cancel"), role: .cancel) {
                    roadPendingDeletion = nil
                }
            } message: { road in
                Text(L10n.format("road.delete.confirm.message", road.name))
            }
        }
    }
}

private struct RoadSettingsRow: View {
    let road: RewardRoad
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill((isSelected ? AppColors.coral : AppColors.sun).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: isSelected ? "map.fill" : "map")
                    .foregroundStyle(isSelected ? AppColors.coral : AppColors.sun)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(road.name)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                Text(L10n.format("road.stamp-count", road.entries.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.mint)
                    .accessibilityLabel(L10n.string("road.selected.accessibility"))
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    RoadSettingsView()
        .environment(
            StampStore(fileURL: URL.temporaryDirectory.appending(path: "road-settings-preview.json"))
        )
}
