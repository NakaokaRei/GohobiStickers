import SwiftUI

/// Displays the whole attachment without cropping it to the preview container.
struct AttachedPhotoPreview: View {
    let image: UIImage
    var cornerRadius: CGFloat = 14

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background.opacity(0.7))
            .clipShape(previewShape)
            .overlay {
                previewShape
                    .stroke(AppColors.ink.opacity(0.08), lineWidth: 1)
            }
    }

    private var previewShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

struct AttachedPhotoThumbnail: View {
    let image: UIImage
    let maximumSize: CGSize

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: fittedSize.width, height: fittedSize.height)
            .clipShape(thumbnailShape)
            .overlay {
                thumbnailShape
                    .stroke(AppColors.ink.opacity(0.1), lineWidth: 1)
            }
    }

    private var fittedSize: CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return maximumSize }
        let scale = min(
            maximumSize.width / image.size.width,
            maximumSize.height / image.size.height
        )
        return CGSize(
            width: max(1, image.size.width * scale),
            height: max(1, image.size.height * scale)
        )
    }

    private var thumbnailShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }
}

struct AttachedPhotoViewer: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 12)
                .accessibilityLabel(L10n.string("stamp.image.preview.accessibility"))
                .accessibilityIdentifier("stamp-image-viewer-photo")

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.55), in: Circle())
                    }
                    .accessibilityLabel(L10n.string("common.close"))
                    .accessibilityIdentifier("stamp-image-viewer-close-button")
                }
                Spacer()
            }
            .padding()
        }
    }
}
