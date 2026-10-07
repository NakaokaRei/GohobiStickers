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
                        .font(.system(size: entry.snapshot.totalStampCount >= 1000 ? 22 : 30, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .foregroundStyle(Color(red: 0.18, green: 0.26, blue: 0.32))
                .frameInArtwork(entry.artwork.total, size: proxy.size)

                CheerLettering()
                    .frameInArtwork(entry.artwork.cheer, size: proxy.size)
            }
        }
    }

    private var goalNote: some View {
        GeometryReader { proxy in
            rewardMessage(compact: true, noteSize: proxy.size)
                .frame(width: proxy.size.width * 0.84, height: proxy.size.height * 0.78)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .background {
            Image("crayon_patch")
                .resizable()
                .accessibilityHidden(true)
        }
    }

    private func rewardMessage(compact: Bool, noteSize: CGSize = .zero) -> some View {
        // Fit two readable lines to each character's differently shaped note.
        let noteFont = min(12, noteSize.height * 0.34, noteSize.width * 0.84 / 5)
        let captionFont = min(10, noteSize.height * 0.29, noteSize.width * 0.84 / 6)
        let countFont = min(15, noteSize.height * 0.40)
        return VStack(spacing: compact ? 0 : 1) {
            if let remaining = entry.snapshot.remainingCount {
                Text(WidgetL10n.string("widget.reward-short"))
                    .font(.system(size: compact ? captionFont : 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
                Text(WidgetL10n.format("widget.remaining.format", remaining))
                    .font(.system(size: compact ? countFont : 22, weight: .bold, design: .rounded))
                    .lineLimit(1)
            } else {
                ForEach(Array(WidgetL10n.string("widget.set-reward").components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: compact ? noteFont : 15, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.65)
        .foregroundStyle(compact ? Color(red: 0.23, green: 0.28, blue: 0.26) : entry.artwork.mediumInk)
    }

    private var history: [String] { entry.recentStampAssetNames }

    private var mediumView: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let centered = entry.artwork.mediumIsCentered
            let contentX = entry.artwork.mediumContentOnRight ? 0.74 : 0.27
            ZStack {
                Image(entry.artwork.mediumAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .accessibilityHidden(true)

                if centered {
                    ForEach([0.105, 0.895], id: \.self) { column in
                        Path { path in
                            let x = width * column
                            let bend = height * 0.055 * (column < 0.5 ? 1.0 : -1.0)
                            path.move(to: CGPoint(x: x - bend, y: height * 0.045))
                            path.addCurve(to: CGPoint(x: x, y: height * 0.26),
                                          control1: CGPoint(x: x - bend, y: height * 0.13),
                                          control2: CGPoint(x: x + bend, y: height * 0.18))
                            path.addCurve(to: CGPoint(x: x, y: height * 0.53),
                                          control1: CGPoint(x: x - bend, y: height * 0.35),
                                          control2: CGPoint(x: x + bend, y: height * 0.44))
                            path.addCurve(to: CGPoint(x: x, y: height * 0.80),
                                          control1: CGPoint(x: x + bend, y: height * 0.62),
                                          control2: CGPoint(x: x - bend, y: height * 0.71))
                            path.addCurve(to: CGPoint(x: x + bend, y: height * 0.985),
                                          control1: CGPoint(x: x - bend, y: height * 0.88),
                                          control2: CGPoint(x: x + bend, y: height * 0.93))
                        }
                        .stroke(entry.artwork.mediumInk.opacity(0.45),
                                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 5]))
                        .accessibilityHidden(true)
                    }
                    rewardMessage(compact: false)
                        .frame(width: width * 0.48, height: height * 0.24)
                        .position(x: width * 0.5, y: height * 0.15)
                    ForEach(0..<6) { index in
                        stampCircle(asset: index < history.count ? history[index] : nil,
                                    size: height * 0.265)
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -5 : 5))
                            .position(x: width * (index < 3 ? 0.105 : 0.895),
                                      y: height * (0.26 + Double(index % 3) * 0.27))
                    }
                } else {
                    VStack(spacing: 3) {
                        rewardMessage(compact: false)
                            .frame(height: height * 0.20)
                        VStack(spacing: 4) {
                            ForEach(0..<2) { row in
                                HStack(spacing: 5) {
                                    ForEach(0..<3) { column in
                                        let index = row * 3 + column
                                        stampCircle(asset: index < history.count ? history[index] : nil,
                                                    size: min(height * 0.28, width * 0.14))
                                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -4 : 4))
                                    }
                                }
                            }
                        }
                        .background {
                            StampRoad(stampSize: min(height * 0.28, width * 0.14))
                                .stroke(entry.artwork.mediumInk.opacity(0.45),
                                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 5]))
                                .accessibilityHidden(true)
                        }
                        Text(WidgetL10n.format("widget.total.format", entry.snapshot.totalStampCount))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.artwork.mediumInk)
                    }
                    .frame(width: width * 0.47)
                    .position(x: width * contentX, y: height * 0.5)
                }
            }
        }
        .accessibilityLabel(WidgetL10n.format("widget.total.format", entry.snapshot.totalStampCount))
    }

    private func stampCircle(asset: String?, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.38))
            if let asset, let image = UIImage(named: asset) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: max(1, size - 5) * 1.18, height: max(1, size - 5) * 1.18)
                    .frame(width: max(1, size - 5), height: max(1, size - 5))
                    .clipShape(Circle())
            }
            Circle().strokeBorder(entry.artwork.mediumInk.opacity(0.4), lineWidth: 1.3)
            Circle().strokeBorder(Color.brown.opacity(0.18), lineWidth: 0.7)
                .padding(4)
        }
        .frame(width: max(1, size), height: max(1, size))
        .accessibilityHidden(true)
    }
}

private extension View {
    // A fractional second ink pass makes the fine handwritten font legible at widget sizes.
    func handDrawnWeight() -> some View {
        overlay { self.offset(x: 0.35, y: 0.15).accessibilityHidden(true) }
    }

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

/// Generated crayon lettering; live text remains available to VoiceOver and other languages.
private struct CheerLettering: View {
    var body: some View {
        if Locale.preferredLanguages.first?.hasPrefix("ja") == true {
            Image("crayon_cheer")
                .resizable()
                .scaledToFit()
                .accessibilityLabel(WidgetL10n.string("widget.cheer"))
        } else {
            Text(WidgetL10n.string("widget.cheer"))
                .font(.custom("Yomogi-Regular", size: 20).bold())
                .handDrawnWeight()
                .foregroundStyle(Color(red: 0.78, green: 0.40, blue: 0.20))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .rotationEffect(.degrees(-5))
        }
    }
}

/// A winding dotted trail behind the two rows of stamps.
private struct StampRoad: Shape {
    let stampSize: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = stampSize / 2
        let top = radius
        let bottom = rect.height - radius
        let right = rect.width - radius
        var path = Path()
        path.move(to: CGPoint(x: -9, y: 2))
        path.addQuadCurve(to: CGPoint(x: radius, y: top),
                          control: CGPoint(x: -9, y: top))
        path.addLine(to: CGPoint(x: right, y: top))
        path.addCurve(to: CGPoint(x: right, y: bottom),
                      control1: CGPoint(x: rect.width + 18, y: top),
                      control2: CGPoint(x: rect.width + 18, y: bottom))
        path.addLine(to: CGPoint(x: radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: -9, y: rect.height - 2),
                          control: CGPoint(x: -9, y: bottom))
        return path
    }
}
