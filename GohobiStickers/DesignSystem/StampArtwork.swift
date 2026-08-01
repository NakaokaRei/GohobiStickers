import SwiftUI
import UIKit

struct StampArtwork: View {
    let preset: StampPreset
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(fallbackColor.opacity(0.17))

            if let image = UIImage(named: preset.assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: preset.fallbackSymbol)
                    .font(.system(size: size * 0.43, weight: .bold))
                    .foregroundStyle(fallbackColor)
            }

            Circle()
                .strokeBorder(AppColors.surfaceHighlight, lineWidth: max(3, size * 0.06))
        }
        .frame(width: size, height: size)
        .shadow(color: fallbackColor.opacity(0.2), radius: 7, y: 4)
    }

    private var fallbackColor: Color {
        switch preset.fallbackColorName {
        case "sun": AppColors.sun
        case "flower": .pink
        case "crown": .orange
        case "heart": AppColors.coral
        case "sparkle": .purple
        case "green": .green
        default: AppColors.sky
        }
    }
}
