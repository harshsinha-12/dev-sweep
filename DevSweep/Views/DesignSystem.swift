import SwiftUI

enum DS {
    static let accent = Color(red: 0.08, green: 0.39, blue: 0.37)
    static let cyan = Color(red: 0.30, green: 0.68, blue: 0.64)
    static let mint = Color(red: 0.22, green: 0.57, blue: 0.49)
    static let amber = Color(red: 0.72, green: 0.50, blue: 0.24)
    static let bronze = Color(red: 0.52, green: 0.36, blue: 0.25)
    static let coral = Color(red: 0.76, green: 0.31, blue: 0.28)
    static let ink = Color(red: 0.105, green: 0.10, blue: 0.09)
    static let canvas = Color(red: 0.955, green: 0.948, blue: 0.925)
    static let surface = Color(red: 0.985, green: 0.982, blue: 0.968)
    static let stone = Color(red: 0.935, green: 0.925, blue: 0.895)

    static let contentCornerRadius: CGFloat = 22
    static let compactCornerRadius: CGFloat = 13
    static let pagePadding: CGFloat = 22

    static var panelFill: Color {
        surface.opacity(0.92)
    }

    static var insetFill: Color {
        stone.opacity(0.72)
    }
}

struct AppBackdrop: View {
    var body: some View {
        ZStack {
            DS.canvas

            LinearGradient(
                colors: [
                    Color.white.opacity(0.36),
                    Color.clear,
                    DS.accent.opacity(0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(red: 0.76, green: 0.57, blue: 0.39).opacity(0.08), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 620
            )

            RadialGradient(
                colors: [DS.accent.opacity(0.045), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 580
            )
        }
        .allowsHitTesting(false)
    }
}

struct PanelBackground: ViewModifier {
    var cornerRadius: CGFloat = DS.contentCornerRadius
    var selected = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        selected
                            ? DS.accent.opacity(0.11)
                            : DS.surface.opacity(0.94)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? DS.accent.opacity(0.40) : DS.ink.opacity(0.075),
                        lineWidth: selected ? 1.25 : 0.75
                    )
            )
            .shadow(color: DS.ink.opacity(0.045), radius: 16, y: 7)
    }
}

extension View {
    func panelBackground(
        cornerRadius: CGFloat = DS.contentCornerRadius,
        selected: Bool = false
    ) -> some View {
        modifier(PanelBackground(cornerRadius: cornerRadius, selected: selected))
    }
}

struct SectionEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.7)
            .foregroundStyle(.secondary)
    }
}
