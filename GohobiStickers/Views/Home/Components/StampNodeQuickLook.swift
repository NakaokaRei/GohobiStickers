import SwiftUI

struct StampNodeQuickLook: View {
    let entry: StampEntry
    let image: UIImage?

    init(entry: StampEntry, image: UIImage? = nil) {
        self.entry = entry
        self.image = image
    }

    private var preset: StampPreset {
        .preset(for: entry.presetID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 12) {
                StampArtwork(preset: preset, size: StampMetrics.quickLookArtworkSize)

                VStack(spacing: 5) {
                    Text(L10n.string("node.quick-look.title"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(preset.name)
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.ink)
                        .lineLimit(2)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("stamp-node-quick-look")

            if let image {
                HStack(alignment: .top, spacing: 14) {
                    noteSummary
                        .layoutPriority(1)

                    AttachedPhotoThumbnail(
                        image: image,
                        maximumSize: CGSize(width: 108, height: 132)
                    )
                    .accessibilityLabel(L10n.string("stamp.image.preview.accessibility"))
                    .accessibilityIdentifier("stamp-quick-look-image")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                noteSummary
            }

            dateSummary
        }
        .padding(18)
        .frame(width: 320, alignment: .leading)
        .background(AppColors.surface)
        .accessibilityElement(children: .contain)
    }

    private var noteSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.string("node.quick-look.comment"), systemImage: "text.bubble")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.coral)

            Text(
                entry.comment.isEmpty
                    ? L10n.string("node.quick-look.comment.empty")
                    : entry.comment
            )
            .font(.body)
            .foregroundStyle(entry.comment.isEmpty ? Color.secondary : AppColors.ink)
            .lineLimit(6)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateSummary: some View {
        Label {
            Text(
                entry.createdAt.formatted(
                    .dateTime.year().month().day().hour().minute()
                )
            )
        } icon: {
            Image(systemName: "calendar")
                .foregroundStyle(AppColors.coral)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.background.opacity(0.6),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
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
