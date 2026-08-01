import SwiftUI

struct RouteConnector: View {
    let from: CGFloat
    let to: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2 + from, y: 0))
            path.addCurve(
                to: CGPoint(x: size.width / 2 + to, y: size.height),
                control1: CGPoint(x: size.width / 2 + from, y: size.height * 0.55),
                control2: CGPoint(x: size.width / 2 + to, y: size.height * 0.45)
            )
            context.stroke(
                path,
                with: .color(AppColors.route),
                style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [3, 18])
            )
        }
        .frame(height: 50)
        .accessibilityHidden(true)
    }
}
