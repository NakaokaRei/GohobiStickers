import SwiftUI
import UIKit
import WidgetKit

struct GohobiWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GohobiTimelineEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .padding(16)
        .foregroundStyle(WidgetPalette.ink)
        .accessibilityElement(children: .combine)
    }

    private var smallView: some View {
        ZStack(alignment: .bottomTrailing) {
            decorativeCircles

            VStack(alignment: .leading, spacing: 3) {
                if let remainingCount = entry.snapshot.remainingCount {
                    Text(WidgetL10n.string(
                        entry.snapshot.totalStampCount == 0
                            ? "widget.no-stamp"
                            : "widget.next-goal"
                    ))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(WidgetL10n.format("widget.remaining.format", remainingCount))
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                } else {
                    Text(WidgetL10n.format(
                        "widget.total.format",
                        entry.snapshot.totalStampCount
                    ))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                    Text(WidgetL10n.string("widget.no-goal"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 42)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            latestStamp(size: 76)
        }
    }

    private var mediumView: some View {
        HStack(spacing: 18) {
            VStack(spacing: 5) {
                latestStamp(size: 106)
                Text(WidgetL10n.string(
                    entry.snapshot.totalStampCount == 0
                        ? "widget.no-stamp"
                        : "widget.latest"
                ))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 116)

            VStack(alignment: .leading, spacing: 7) {
                if let remainingCount = entry.snapshot.remainingCount {
                    Text(WidgetL10n.string("widget.next-goal"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(WidgetL10n.format("widget.remaining.format", remainingCount))
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    Text(entry.snapshot.nextGoalRewardName ?? "")
                        .font(.headline.weight(.bold))
                        .lineLimit(1)

                    progressView
                } else {
                    Text(WidgetL10n.format(
                        "widget.total.format",
                        entry.snapshot.totalStampCount
                    ))
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                    Text(WidgetL10n.string("widget.no-goal"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WidgetPalette.mint)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var progressView: some View {
        if let progress = entry.snapshot.intervalProgress,
           let required = entry.snapshot.intervalRequiredCount {
            ProgressView(value: Double(progress), total: Double(max(1, required)))
                .tint(WidgetPalette.mint)
                .accessibilityValue("\(progress) / \(required)")
        }
    }

    @ViewBuilder
    private func latestStamp(size: CGFloat) -> some View {
        if let image = latestStampImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.9), lineWidth: max(4, size * 0.06))
                }
                .shadow(color: WidgetPalette.mint.opacity(0.2), radius: 8, y: 4)
        } else {
            ZStack {
                Circle().fill(WidgetPalette.sun.opacity(0.18))
                Image(systemName: "seal.fill")
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundStyle(WidgetPalette.sun)
            }
            .frame(width: size, height: size)
            .accessibilityLabel(WidgetL10n.string("widget.no-stamp"))
        }
    }

    private var latestStampImage: UIImage? {
        guard let assetName = entry.snapshot.latestStampAssetName else { return nil }
        return UIImage(named: assetName, in: .main, compatibleWith: nil)
    }

    private var decorativeCircles: some View {
        ZStack {
            Circle()
                .fill(WidgetPalette.sun.opacity(0.11))
                .frame(width: 110, height: 110)
                .offset(x: 54, y: -48)
            Circle()
                .fill(WidgetPalette.mint.opacity(0.09))
                .frame(width: 92, height: 92)
                .offset(x: -62, y: 60)
        }
        .allowsHitTesting(false)
    }
}

enum WidgetPalette {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.085, blue: 0.095, alpha: 1)
            : UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1)
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1)
            : UIColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 1)
    })
    static let mint = Color(red: 0.18, green: 0.63, blue: 0.52)
    static let sun = Color(red: 0.97, green: 0.67, blue: 0.16)
}

enum WidgetL10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ value: Int) -> String {
        String.localizedStringWithFormat(string(key), Int64(value))
    }
}
