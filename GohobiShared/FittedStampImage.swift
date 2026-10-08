import SwiftUI
import UIKit

/// Keeps the supplied illustrations inside the circular border, including their feet and tails.
struct FittedStampImage: View {
    let image: UIImage
    let assetName: String
    let size: CGFloat
    let borderWidth: CGFloat

    var body: some View {
        ZStack {
            if let background = artworkBackground {
                background
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(borderWidth + size * 0.025)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // RGB pixel values sampled from the solid backgrounds of the supplied artwork.
    // These nine illustrations fit within the image's inscribed circle.
    private var artworkBackground: Color? {
        switch assetName {
        case "stamp_blue_hero": Color(.sRGB, red: 236 / 255.0, green: 206 / 255.0, blue: 173 / 255.0)
        case "stamp_pink_hero": Color(.sRGB, red: 240 / 255.0, green: 219 / 255.0, blue: 228 / 255.0)
        case "stamp_sea_lion": Color(.sRGB, red: 136 / 255.0, green: 197 / 255.0, blue: 229 / 255.0)
        case "stamp_penguin_pink": Color(.sRGB, red: 251 / 255.0, green: 209 / 255.0, blue: 211 / 255.0)
        case "stamp_butterfly_blue": Color(.sRGB, red: 173 / 255.0, green: 229 / 255.0, blue: 232 / 255.0)
        case "stamp_lemon_hero": Color(.sRGB, red: 187 / 255.0, green: 211 / 255.0, blue: 195 / 255.0)
        case "stamp_glowing_fish": Color(.sRGB, red: 126 / 255.0, green: 167 / 255.0, blue: 203 / 255.0)
        case "stamp_starfish_purple": Color(.sRGB, red: 116 / 255.0, green: 101 / 255.0, blue: 128 / 255.0)
        case "stamp_koala_green": Color(.sRGB, red: 137 / 255.0, green: 171 / 255.0, blue: 125 / 255.0)
        default: nil
        }
    }
}
