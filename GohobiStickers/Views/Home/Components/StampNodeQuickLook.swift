import SwiftUI

struct StampNodeQuickLook: View {
    let entry: StampEntry

    private var preset: StampPreset {
        .preset(for: entry.presetID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                StampArtwork(preset: preset, size: 104)

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.string("node.quick-look.title"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(preset.name)
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.ink)
                        .lineLimit(2)
                }
            }

            Divider()

            detailRow(
                title: L10n.string("node.quick-look.date"),
                systemImage: "calendar",
                value: entry.createdAt.formatted(
                    .dateTime.year().month().day().hour().minute()
                )
            )

            detailRow(
                title: L10n.string("node.quick-look.note"),
                systemImage: "text.bubble",
                value: entry.comment.isEmpty
                    ? L10n.string("node.quick-look.note.empty")
                    : entry.comment,
                isSecondary: entry.comment.isEmpty
            )
        }
        .padding(22)
        .frame(width: 320, alignment: .leading)
        .background(AppColors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stamp-node-quick-look")
    }

    private func detailRow(
        title: String,
        systemImage: String,
        value: String,
        isSecondary: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.coral)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(isSecondary ? Color.secondary : AppColors.ink)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    StampNodeQuickLook(
        entry: StampEntry(
            presetID: "frog_green",
            comment: "今日は最後まで集中して取り組めた！"
        )
    )
    .preferredColorScheme(.light)
}
