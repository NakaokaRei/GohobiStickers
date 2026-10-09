import SwiftUI
import UIKit

struct PrintedTrailMediumWidgetView: View {
    let entry: GohobiTimelineEntry
    private var history: [String] { entry.recentStampAssetNames }

    var body: some View {
        GeometryReader { proxy in
            // Use the same aspect-fill transform for the art and every overlay,
            // so stamps stay on the printed trail at all Medium widget sizes.
            let canvasWidth = max(proxy.size.width, proxy.size.height * 2)
            let canvasHeight = canvasWidth / 2
            let penguin = entry.artwork.id == "penguin_pink"
            let ink = Color(red: 0.46, green: 0.41, blue: 0.41)
            ZStack(alignment: .topLeading) {
                Image(entry.artwork.mediumAssetName)
                    .resizable()
                    .frame(width: canvasWidth, height: canvasHeight)
                    .accessibilityHidden(true)

                ForEach(Array(history.prefix(6).enumerated()), id: \.offset) { index, asset in
                    let center = entry.artwork.mediumStampCenters[index]
                    if let image = UIImage(named: asset) {
                        let size = canvasHeight * 0.235
                        ZStack {
                            Circle().fill(Color.white.opacity(0.38))
                            FittedStampImage(image: image, assetName: asset,
                                             size: max(1, size - 5), borderWidth: 2)
                            Circle()
                                .strokeBorder(entry.artwork.mediumInk.opacity(0.4), lineWidth: 1.3)
                            Circle()
                                .strokeBorder(Color.brown.opacity(0.18), lineWidth: 0.7)
                                .padding(4)
                        }
                            .frame(width: size, height: size)
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -4 : 4))
                            .position(x: canvasWidth * center.x, y: canvasHeight * center.y)
                            .accessibilityHidden(true)
                    }
                }

                if let remaining = entry.snapshot.remainingCount {
                    Text(WidgetL10n.string("widget.reward-short"))
                        .font(WidgetArtworkFont.font(size: canvasHeight * 0.050, bold: true))
                        .tracking(canvasWidth * 0.0018)
                        .frame(width: canvasWidth * 0.25, height: canvasHeight * 0.09)
                        .position(x: canvasWidth * (penguin ? 0.46 : 0.574),
                                  y: canvasHeight * 0.095)
                    remainingLabel(remaining, height: canvasHeight)
                        .frame(width: canvasWidth * 0.24, height: canvasHeight * 0.15)
                        .position(x: canvasWidth * (penguin ? 0.54 : 0.69),
                                  y: canvasHeight * 0.195)
                } else {
                    Text(WidgetL10n.string("widget.set-reward").replacingOccurrences(of: "\n", with: " "))
                        .font(WidgetArtworkFont.font(size: canvasHeight * 0.065, bold: true))
                        .frame(width: canvasWidth * 0.32, height: canvasHeight * 0.18)
                        .position(x: canvasWidth * (penguin ? 0.50 : 0.62),
                                  y: canvasHeight * 0.15)
                }

                Text(WidgetL10n.format("widget.total.compact-format", entry.snapshot.totalStampCount))
                    .font(WidgetArtworkFont.font(size: canvasHeight * 0.050))
                    .tracking(canvasWidth * 0.001)
                    .padding(.horizontal, canvasWidth * 0.012)
                    .frame(width: canvasWidth * 0.15, height: canvasHeight * 0.095)
                    .background(Color(red: 0.80, green: 0.76, blue: 0.66), in: Capsule())
                    .position(x: canvasWidth * (penguin ? 0.52 : 0.576),
                              y: canvasHeight * 0.905)
            }
            .foregroundStyle(ink)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: canvasWidth, height: canvasHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .clipped()
    }

    private func remainingLabel(_ count: Int, height: CGFloat) -> some View {
        // Keep the translated sentence intact while emphasizing only its number.
        // Match the locale's grouping separators used by the translated format.
        let number = String.localizedStringWithFormat("%lld", Int64(count))
        let sentence = WidgetL10n.format("widget.remaining.format", count)
        var text = AttributedString(sentence)
        text.font = WidgetArtworkFont.font(size: height * 0.058, bold: true)
        text.kern = height * 0.012
        text.baselineOffset = height * 0.022
        if let range = text.range(of: number) {
            text[range].font = WidgetArtworkFont.font(size: height * 0.136, bold: true)
            text[range].baselineOffset = 0
        }
        return Text(text)
    }

}

/// Use a legitimately installed/bundled Tsukushi face when available. Never
/// redistribute the macOS font; shipping it requires an app-embedding license.
private enum WidgetArtworkFont {
    static func font(size: CGFloat, bold: Bool = false) -> Font {
        let names = bold
            ? ["TsukuARdGothic-Bold", "TsukuARdGothicStd-B", "TsukuARdGothic-Regular", "TsukuARdGothicStd-R"]
            : ["TsukuARdGothic-Regular", "TsukuARdGothicStd-R"]
        for name in names where UIFont(name: name, size: size) != nil {
            return .custom(name, fixedSize: size)
        }
        if UIFont(name: "HiraMaruProN-W4", size: size) != nil {
            let font = Font.custom("HiraMaruProN-W4", fixedSize: size)
            return bold ? font.bold() : font
        }
        return .system(size: size, weight: bold ? .semibold : .regular, design: .rounded)
    }
}
