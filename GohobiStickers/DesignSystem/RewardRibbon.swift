import SwiftUI

/// A flexible ribbon whose center grows with the text, keeping the folded tails clear.
struct RewardRibbon<Content: View>: View {
    @ViewBuilder let content: Content

    private let paper = Color(red: 1, green: 0.91, blue: 0.70)
    private let edge = Color(red: 0.57, green: 0.39, blue: 0.21)

    var body: some View {
        content
            .foregroundStyle(Color(red: 0.32, green: 0.24, blue: 0.18))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(paper, in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(edge.opacity(0.75), lineWidth: 1.5)
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 12)
            .background(alignment: .bottom) {
                HStack(spacing: 0) {
                    tail
                    Spacer(minLength: 0)
                    tail.scaleEffect(x: -1, y: 1)
                }
                .accessibilityHidden(true)
            }
    }

    private var tail: some View {
        RibbonTail()
            .fill(Color(red: 0.96, green: 0.81, blue: 0.55))
            .overlay { RibbonTail().stroke(edge.opacity(0.75), lineWidth: 1.5) }
            .frame(width: 42, height: 28)
    }

    private struct RibbonTail: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: 1, y: 2))
                p.addLine(to: CGPoint(x: rect.maxX - 1, y: 0))
                p.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY - 5))
                p.addLine(to: CGPoint(x: 0, y: rect.maxY))
                p.addLine(to: CGPoint(x: 7, y: rect.midY))
                p.closeSubpath()
            }
        }
    }
}
