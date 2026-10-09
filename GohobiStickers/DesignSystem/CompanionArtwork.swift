import SwiftUI
import UIKit

/// Original transparent artwork, framed around the illustrated content rather than its empty canvas.
enum Companion: String, CaseIterable {
    case seaLions = "road_sea_lions"
    case rabbit = "road_rabbit"
    case rabbits = "road_rabbits"
    case seal = "celebration_seal"
    case penguin = "celebration_penguin"

    var bounds: CGRect {
        switch self {
        case .seaLions: CGRect(x: 0.025, y: 0, width: 0.96, height: 0.98)
        case .rabbit: CGRect(x: 0.18, y: 0.28, width: 0.65, height: 0.42)
        case .rabbits: CGRect(x: 0.07, y: 0.07, width: 0.89, height: 0.80)
        case .seal: CGRect(x: 0.075, y: 0.29, width: 0.82, height: 0.455)
        case .penguin: CGRect(x: 0.16, y: 0.17, width: 0.63, height: 0.64)
        }
    }

    var canvasAspectRatio: CGFloat {
        switch self {
        case .seaLions: 3102 / 1633
        case .rabbits: 2806 / 2264
        default: 1
        }
    }
}

@MainActor
private enum CompanionImageCache {
    private static let images = NSCache<NSString, UIImage>()

    static func image(for companion: Companion) -> UIImage {
        let key = companion.rawValue as NSString
        if let image = images.object(forKey: key) { return image }
        guard let source = UIImage(named: companion.rawValue) else { return UIImage() }
        // The supplied canvases are up to 5,214 px; keep display textures appropriately sized.
        let image = source.preparingThumbnail(of: CGSize(width: 1024, height: 1024)) ?? source
        images.setObject(image, forKey: key)
        return image
    }
}

struct CompanionArtwork: View {
    let companion: Companion

    var body: some View {
        let bounds = companion.bounds
        GeometryReader { proxy in
            Image(uiImage: CompanionImageCache.image(for: companion))
                .resizable()
                .frame(width: proxy.size.width / bounds.width, height: proxy.size.height / bounds.height)
                .offset(x: -bounds.minX * proxy.size.width / bounds.width,
                        y: -bounds.minY * proxy.size.height / bounds.height)
        }
        .aspectRatio(companion.canvasAspectRatio * bounds.width / bounds.height, contentMode: .fit)
        .clipped()
        .accessibilityHidden(true)
    }
}

/// A reproducible random selection keeps a goal's celebration and exported card in sync.
struct CelebrationStyle {
    let companion: Companion
    let messageKey: String

    init(id: UUID) {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        companion = bytes[0].isMultiple(of: 2) ? .seal : .penguin
        messageKey = ["celebration.cheer.amazing", "celebration.cheer.celebrate",
                      "celebration.cheer.rest", "celebration.cheer.congratulations"][Int(bytes[1]) % 4]
    }
}

struct CelebrationCompanion: View {
    let id: UUID
    var compact = false

    var body: some View {
        let style = CelebrationStyle(id: id)
        VStack(spacing: 12) {
            Text(L10n.string(style.messageKey))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .padding(.bottom, 10)
                .background { SpeechBubble().fill(AppColors.background) }
                .overlay { SpeechBubble().stroke(AppColors.ink.opacity(0.55), lineWidth: 1.5) }

            HStack(spacing: 12) {
                CelebrationStarCluster(isTrailing: false)
                    .frame(width: 44, height: compact ? 100 : 112)
                CompanionArtwork(companion: style.companion)
                    .frame(width: compact ? 130 : 152, height: compact ? 100 : 112)
                CelebrationStarCluster(isTrailing: true)
                    .frame(width: 44, height: compact ? 100 : 112)
            }
            .foregroundStyle(AppColors.sun)
            .accessibilityHidden(true)
        }
    }
}

/// Four stars per side stay inside dedicated space, clear of the mascot and text.
private struct CelebrationStarCluster: View {
    let isTrailing: Bool

    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double)] = [
        (0.30, 0.12, 18, -18),
        (0.78, 0.34, 12, 14),
        (0.30, 0.59, 26, -12),
        (0.70, 0.87, 16, 22)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(stars.indices, id: \.self) { index in
                let star = stars[index]
                CelebrationStar(size: star.size)
                    .rotationEffect(.degrees(isTrailing ? -star.angle : star.angle))
                    .position(
                        x: proxy.size.width * (isTrailing ? 1 - star.x : star.x),
                        y: proxy.size.height * (isTrailing ? 1 - star.y : star.y)
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Shared on both sides of the mascot, with softly curved tips and valleys.
private struct CelebrationStar: View {
    var size: CGFloat = 28

    var body: some View {
        RoundedStar()
            .stroke(style: StrokeStyle(lineWidth: max(1.4, size * 0.075), lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }

    private struct RoundedStar: Shape {
        func path(in rect: CGRect) -> Path {
            let radius = min(rect.width, rect.height) * 0.45
            let points = (0..<10).map { index in
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let distance = index.isMultiple(of: 2) ? radius : radius * 0.52
                return CGPoint(x: rect.midX + cos(angle) * distance,
                               y: rect.midY + sin(angle) * distance)
            }
            func approach(_ vertex: CGPoint, from neighbor: CGPoint) -> CGPoint {
                CGPoint(x: vertex.x + (neighbor.x - vertex.x) * 0.24,
                        y: vertex.y + (neighbor.y - vertex.y) * 0.24)
            }
            return Path { path in
                path.move(to: approach(points[0], from: points[9]))
                for index in points.indices {
                    let vertex = points[index]
                    path.addLine(to: approach(vertex, from: points[(index + 9) % 10]))
                    path.addQuadCurve(to: approach(vertex, from: points[(index + 1) % 10]),
                                      control: vertex)
                }
                path.closeSubpath()
            }
        }
    }
}

struct RoadCompanion: View {
    let roadID: UUID
    let position: Int
    let nodeOffset: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Only the outside of a bend has enough clear space for an illustration.
        if nodeOffset != 0 {
            let seed = roadID.uuidString.utf8.reduce(UInt64(position) &* 1099511628211) { ($0 ^ UInt64($1)) &* 1099511628211 }
            let companion: Companion = [.rabbit, .rabbits, .seaLions][Int(seed % 3)]
            GeometryReader { proxy in
                CompanionArtwork(companion: companion)
                    .frame(width: min(104, proxy.size.width * 0.29), height: 84)
                    .brightness(colorScheme == .dark ? 0.55 : 0)
                    .rotationEffect(.degrees(Double(Int(seed % 11) - 5)))
                    .position(x: proxy.size.width / 2 + (nodeOffset < 0 ? 85 : -85),
                              y: proxy.size.height / 2 + CGFloat(Int(seed % 17) - 8))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// A single closed outline avoids a seam where the speech bubble meets its tail.
private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = min(24, rect.height / 2)
        let bottom = rect.maxY - 10
        let tail = rect.midX + min(28, rect.width * 0.15)
        return Path { p in
            p.move(to: CGPoint(x: r, y: 0))
            p.addLine(to: CGPoint(x: rect.maxX - r, y: 0))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: r), control: CGPoint(x: rect.maxX, y: 0))
            p.addLine(to: CGPoint(x: rect.maxX, y: bottom - r))
            p.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: bottom), control: CGPoint(x: rect.maxX, y: bottom))
            p.addLine(to: CGPoint(x: tail + 12, y: bottom))
            p.addQuadCurve(to: CGPoint(x: tail, y: rect.maxY), control: CGPoint(x: tail + 8, y: rect.maxY))
            p.addLine(to: CGPoint(x: tail - 3, y: bottom))
            p.addLine(to: CGPoint(x: r, y: bottom))
            p.addQuadCurve(to: CGPoint(x: 0, y: bottom - r), control: CGPoint(x: 0, y: bottom))
            p.addLine(to: CGPoint(x: 0, y: r))
            p.addQuadCurve(to: CGPoint(x: r, y: 0), control: .zero)
            p.closeSubpath()
        }
    }
}
