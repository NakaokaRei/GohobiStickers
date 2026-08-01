import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(StampStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                cloudSyncSection
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

    private var appearanceSection: some View {
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
    }

    private var cloudSyncSection: some View {
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
