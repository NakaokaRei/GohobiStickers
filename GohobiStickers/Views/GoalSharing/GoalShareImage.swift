import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct GoalShareImage: Transferable, Sendable {
    let pngData: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            image.pngData
        }
        .suggestedFileName { image in
            image.fileName
        }

        FileRepresentation(exportedContentType: .png) { image in
            let url = FileManager.default.temporaryDirectory
                .appending(path: image.fileName, directoryHint: .notDirectory)
            try image.pngData.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

struct RenderedGoalShareCard {
    let image: UIImage
    let shareImage: GoalShareImage
}

enum GoalShareCardRenderer {
    @MainActor
    static func render(_ data: GoalShareCardData) -> RenderedGoalShareCard? {
        let content = GoalAchievementCard(data: data)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: GoalAchievementCard.width, height: nil)
        renderer.scale = 3

        guard
            let renderedImage = renderer.uiImage,
            let image = roundedImage(from: renderedImage),
            let pngData = image.pngData()
        else {
            return nil
        }

        return RenderedGoalShareCard(
            image: image,
            shareImage: GoalShareImage(
                pngData: pngData,
                fileName: fileName(for: data)
            )
        )
    }

    private static func fileName(for data: GoalShareCardData) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "gohobi-goal-\(data.rangeEnd)-\(formatter.string(from: data.achievedAt)).png"
    }

    private static func roundedImage(from image: UIImage) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false

        let bounds = CGRect(origin: .zero, size: image.size)
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: GoalAchievementCard.cornerRadius
            ).addClip()
            image.draw(in: bounds)
        }
    }
}
