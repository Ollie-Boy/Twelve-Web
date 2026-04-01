import SwiftUI

struct TwelvePrimaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TwelveTheme.appFont(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                TwelveTheme.primaryBlue.opacity(configuration.isPressed ? 0.85 : 1.0),
                                TwelveTheme.primaryBlueDark.opacity(configuration.isPressed ? 0.88 : 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.8)
            )
            .shadow(color: TwelveTheme.primaryBlue.opacity(configuration.isPressed ? 0.1 : 0.24), radius: 12, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct TwelvePillButtonStyle: ButtonStyle {
    var accent: Color = TwelveTheme.surfaceTintBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TwelveTheme.appFont(size: 13, weight: .medium))
            .foregroundStyle(TwelveTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(accent.opacity(configuration.isPressed ? 0.75 : 1.0))
            )
            .overlay(
                Capsule().stroke(TwelveTheme.strokeSoft, lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}
