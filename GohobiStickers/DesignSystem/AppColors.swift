import SwiftUI
import UIKit

enum AppColors {
    static let background = adaptive(
        light: UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1),
        dark: UIColor(red: 0.07, green: 0.075, blue: 0.085, alpha: 1)
    )
    static let surface = adaptive(
        light: UIColor(white: 1, alpha: 0.9),
        dark: UIColor(red: 0.14, green: 0.145, blue: 0.16, alpha: 1)
    )
    static let surfaceHighlight = adaptive(
        light: UIColor(white: 1, alpha: 0.96),
        dark: UIColor(white: 1, alpha: 0.16)
    )
    static let ink = adaptive(
        light: UIColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1)
    )
    static let coral = Color(red: 0.95, green: 0.35, blue: 0.30)
    static let mint = Color(red: 0.18, green: 0.63, blue: 0.52)
    static let sun = Color(red: 0.97, green: 0.67, blue: 0.16)
    static let sky = Color(red: 0.28, green: 0.62, blue: 0.88)
    static let route = adaptive(
        light: UIColor(red: 0.76, green: 0.69, blue: 0.58, alpha: 0.55),
        dark: UIColor(red: 0.48, green: 0.49, blue: 0.53, alpha: 0.7)
    )
    static let emptyNode = adaptive(
        light: UIColor(red: 0.91, green: 0.87, blue: 0.78, alpha: 1),
        dark: UIColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
