import Foundation
import UIKit

nonisolated enum StampImageStoreError: LocalizedError, Sendable {
    case invalidImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            L10n.string("stamp.image.error.invalid")
        case .encodingFailed:
            L10n.string("stamp.image.error.save")
        }
    }
}

@MainActor
final class StampImageStore {
    nonisolated static let maximumPixelLength = 1_600
    nonisolated static let jpegQuality = 0.82

    private let directoryURL: URL
    private let fileManager: FileManager
    private let cache = NSCache<NSString, UIImage>()

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL(fileManager: fileManager)
        self.fileManager = fileManager
    }

    func normalizedJPEG(from sourceData: Data) throws -> Data {
        try Self.normalizedJPEGData(from: sourceData)
    }

    nonisolated static func normalizedJPEGData(from sourceData: Data) throws -> Data {
        try autoreleasepool {
            guard
                let sourceImage = UIImage(data: sourceData),
                sourceImage.size.width > 0,
                sourceImage.size.height > 0
            else {
                throw StampImageStoreError.invalidImage
            }

            let pixelWidth = sourceImage.size.width * sourceImage.scale
            let pixelHeight = sourceImage.size.height * sourceImage.scale
            let scale = min(1, CGFloat(maximumPixelLength) / max(pixelWidth, pixelHeight))
            let renderSize = CGSize(
                width: max(1, (pixelWidth * scale).rounded()),
                height: max(1, (pixelHeight * scale).rounded())
            )
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let normalizedImage = UIGraphicsImageRenderer(size: renderSize, format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: renderSize))
                sourceImage.draw(in: CGRect(origin: .zero, size: renderSize))
            }

            guard let data = normalizedImage.jpegData(compressionQuality: jpegQuality) else {
                throw StampImageStoreError.encodingFailed
            }
            return data
        }
    }

    func saveSourceData(_ sourceData: Data, entryID: UUID, revision: UUID) throws {
        try saveNormalizedData(normalizedJPEG(from: sourceData), entryID: entryID, revision: revision)
    }

    func saveNormalizedData(_ data: Data, entryID: UUID, revision: UUID) throws {
        guard let image = validatedJPEG(from: data) else {
            throw StampImageStoreError.invalidImage
        }
        let destination = fileURL(entryID: entryID, revision: revision)
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try data.write(to: destination, options: .atomic)
        } catch {
            throw StampImageStoreError.encodingFailed
        }
        cache.setObject(image, forKey: destination.path as NSString)
    }

    func image(for entry: StampEntry) -> UIImage? {
        guard let revision = entry.imageRevision else { return nil }
        let url = fileURL(entryID: entry.id, revision: revision)
        if let cached = cache.object(forKey: url.path as NSString) {
            return cached
        }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: url.path as NSString)
        return image
    }

    func data(entryID: UUID, revision: UUID) throws -> Data {
        try Data(contentsOf: fileURL(entryID: entryID, revision: revision))
    }

    func contains(entryID: UUID, revision: UUID) -> Bool {
        let url = fileURL(entryID: entryID, revision: revision)
        guard let data = try? Data(contentsOf: url) else { return false }
        return validatedJPEG(from: data) != nil
    }

    func fileURL(entryID: UUID, revision: UUID) -> URL {
        directoryURL.appending(
            path: "\(entryID.uuidString.lowercased())-\(revision.uuidString.lowercased()).jpg",
            directoryHint: .notDirectory
        )
    }

    func removeImages(for entryID: UUID) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else { return }
        let prefix = entryID.uuidString.lowercased() + "-"
        for file in files where file.lastPathComponent.hasPrefix(prefix) {
            cache.removeObject(forKey: file.path as NSString)
            try? fileManager.removeItem(at: file)
        }
    }

    func removeUnreferencedImages(in data: StampBookData) {
        let referencedNames = Set(
            data.roads.flatMap(\.entries).compactMap { entry -> String? in
                guard let revision = entry.imageRevision else { return nil }
                return fileURL(entryID: entry.id, revision: revision).lastPathComponent
            }
        )
        guard let files = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else { return }
        for file in files where file.pathExtension.lowercased() == "jpg" && !referencedNames.contains(file.lastPathComponent) {
            cache.removeObject(forKey: file.path as NSString)
            try? fileManager.removeItem(at: file)
        }
    }

    private static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return root.appending(path: "GohobiStickers", directoryHint: .isDirectory)
            .appending(path: "StampImages", directoryHint: .isDirectory)
    }

    private func validatedJPEG(from data: Data) -> UIImage? {
        guard
            data.count >= 4,
            data.starts(with: [0xFF, 0xD8]),
            data.suffix(2).elementsEqual([0xFF, 0xD9]),
            let image = UIImage(data: data),
            let cgImage = image.cgImage,
            max(cgImage.width, cgImage.height) <= Self.maximumPixelLength
        else {
            return nil
        }
        return image
    }
}
