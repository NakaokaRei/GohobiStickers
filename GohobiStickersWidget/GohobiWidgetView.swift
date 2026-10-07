import SwiftUI
import UIKit
import WidgetKit

struct GohobiWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GohobiTimelineEntry

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumView
            } else {
                smallView
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var smallView: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Image(entry.artwork.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .accessibilityHidden(true)

                goalNote
                    .frameInArtwork(entry.artwork.goal, size: proxy.size)
                VStack(alignment: .leading, spacing: 0) {
                    Text(WidgetL10n.string("widget.total"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                    Text(WidgetL10n.format("widget.count.format", entry.snapshot.totalStampCount))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .foregroundStyle(Color(red: 0.18, green: 0.26, blue: 0.32))
                .frameInArtwork(entry.artwork.total, size: proxy.size)

                Text(WidgetL10n.string("widget.cheer"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.62, green: 0.28, blue: 0.12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .rotationEffect(.degrees(-5))
                    .frameInArtwork(entry.artwork.cheer, size: proxy.size)
            }
        }
    }

    private var goalNote: some View {
        VStack(spacing: 1) {
            if let remaining = entry.snapshot.remainingCount {
                Text(WidgetL10n.string("widget.next-goal"))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                Text(WidgetL10n.format("widget.remaining.format", remaining))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            } else {
                Text(WidgetL10n.string(entry.snapshot.totalStampCount == 0
                    ? "widget.no-stamp" : "widget.no-goal"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.65)
        .foregroundStyle(Color(red: 0.28, green: 0.33, blue: 0.22))
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.94, green: 0.96, blue: 0.67).opacity(0.96),
                    in: RoundedRectangle(cornerRadius: 13))
    }

    private var history: [String] {
        entry.previousStampAssetNames
    }

    private var mediumView: some View {
        GeometryReader { proxy in
            let latestSize = min(proxy.size.height * 0.61, proxy.size.width * 0.30)
            let stampSize = min((proxy.size.height - 55) / 2, (proxy.size.width * 0.57 - 36) / 3)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(WidgetL10n.string("widget.history"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    VStack(spacing: 6) {
                        ForEach(0..<2) { row in
                            HStack(spacing: 9) {
                                ForEach(0..<3) { column in
                                    let index = row * 3 + column
                                    stampCircle(asset: index < history.count ? history[index] : nil,
                                                size: stampSize)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 3) {
                    Text(WidgetL10n.string(entry.snapshot.totalStampCount == 0
                        ? "widget.no-stamp" : "widget.latest"))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    stampCircle(asset: entry.snapshot.latestStampAssetName == nil
                                ? nil : entry.artwork.stampAssetName, size: latestSize)
                    Text(WidgetL10n.format("widget.total.format", entry.snapshot.totalStampCount))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(width: proxy.size.width * 0.33)
            }
            .padding(12)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .foregroundStyle(WidgetPalette.ink)
    }

    private func stampCircle(asset: String?, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(WidgetPalette.sun.opacity(0.12))
            if let asset, let image = UIImage(named: asset) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: max(1, size - 5), height: max(1, size - 5))
                    .clipShape(Circle())
            }
            Circle().strokeBorder(WidgetPalette.ink.opacity(0.3), lineWidth: 1.5)
            Circle().strokeBorder(WidgetPalette.ink.opacity(0.1), lineWidth: 1)
                .padding(4)
        }
        .frame(width: max(1, size), height: max(1, size))
        .accessibilityHidden(true)
    }
}

private extension View {
    func frameInArtwork(_ rect: CGRect, size: CGSize) -> some View {
        self.frame(width: size.width * rect.width, height: size.height * rect.height)
            .position(x: size.width * rect.midX, y: size.height * rect.midY)
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
