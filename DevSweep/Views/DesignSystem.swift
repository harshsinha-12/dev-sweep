import SwiftUI

enum DS {
    static let accent = Color(red: 0.10, green: 0.66, blue: 0.90)
    static let cyan = Color(red: 0.16, green: 0.78, blue: 0.86)
    static let mint = Color(red: 0.25, green: 0.72, blue: 0.55)
    static let amber = Color(red: 0.82, green: 0.54, blue: 0.27)
    static let bronze = Color(red: 0.66, green: 0.40, blue: 0.23)
    static let coral = Color(red: 0.96, green: 0.39, blue: 0.36)

    static let contentCornerRadius: CGFloat = 22
    static let compactCornerRadius: CGFloat = 13
    static let pagePadding: CGFloat = 22

    static var panelFill: Color {
        Color(nsColor: .controlBackgroundColor).opacity(0.72)
    }

    static var insetFill: Color {
        Color.primary.opacity(0.045)
    }
}

struct AppBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.075, green: 0.064, blue: 0.058),
                        Color(red: 0.105, green: 0.082, blue: 0.067),
                        Color(red: 0.070, green: 0.076, blue: 0.078)
                    ]
                    : [
                        Color(red: 0.96, green: 0.94, blue: 0.91),
                        Color(red: 0.94, green: 0.91, blue: 0.87),
                        Color(red: 0.91, green: 0.92, blue: 0.91)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [DS.bronze.opacity(colorScheme == .dark ? 0.20 : 0.14), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 560
            )

            RadialGradient(
                colors: [DS.accent.opacity(colorScheme == .dark ? 0.075 : 0.08), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 540
            )
        }
        .allowsHitTesting(false)
    }
}

struct PanelBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = DS.contentCornerRadius
    var selected = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        selected
                            ? DS.accent.opacity(0.11)
                            : (
                                colorScheme == .dark
                                    ? Color(red: 0.105, green: 0.095, blue: 0.087).opacity(0.82)
                                    : Color.white.opacity(0.54)
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? DS.accent.opacity(0.46) : Color.white.opacity(0.10),
                        lineWidth: selected ? 1.25 : 0.75
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 16, y: 7)
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
