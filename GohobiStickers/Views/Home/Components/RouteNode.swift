import SwiftUI

struct RouteNode: View {
    let position: Int
    let entry: StampEntry?
    let isNext: Bool
    let offset: CGFloat
    let action: () -> Void

    var body: some View {
        ZStack {
            if let entry {
                completedNode(entry)
            } else {
                emptyNode
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: StampMetrics.routeNodeHeight)
        .offset(x: offset)
    }

    private func completedNode(_ entry: StampEntry) -> some View {
        Button(action: action) {
            StampArtwork(
                preset: .preset(for: entry.presetID),
                size: StampMetrics.routeArtworkSize
            )
                .overlay(alignment: .bottomTrailing) {
                    if !entry.comment.isEmpty {
                        Image(systemName: "text.bubble.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(AppColors.mint, in: Circle())
                            .offset(x: 5, y: 5)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.format(
                "node.completed.accessibility",
                position,
                StampPreset.preset(for: entry.presetID).name
            )
        )
        .accessibilityIdentifier("stamp-node-\(position)")
        .contextMenu {
            Button(action: action) {
                Label(L10n.string("node.quick-look.edit"), systemImage: "pencil")
            }
            .accessibilityIdentifier("stamp-node-quick-look-edit-button")
        } preview: {
            StampNodeQuickLook(entry: entry)
        }
    }

    private var emptyNode: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isNext ? AppColors.coral.opacity(0.16) : AppColors.emptyNode)
                Circle()
                    .strokeBorder(isNext ? AppColors.coral : AppColors.surfaceHighlight, lineWidth: 5)
                if isNext {
                    Image(systemName: "hand.tap.fill")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.coral)
                } else {
                    Text(position, format: .number)
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.ink.opacity(0.48))
                }
            }
            .frame(
                width: StampMetrics.routeEmptyNodeSize,
                height: StampMetrics.routeEmptyNodeSize
            )
            .shadow(color: AppColors.ink.opacity(0.08), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isNext)
        .accessibilityLabel(
            isNext
                ? L10n.format("node.next.accessibility", position)
                : L10n.format("node.empty.accessibility", position)
        )
        .accessibilityIdentifier(isNext ? "next-stamp-node" : "future-stamp-node-\(position)")
    }
}
