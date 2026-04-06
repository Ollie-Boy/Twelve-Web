import SwiftUI

/// Shared sticker-style panel used by the cartoon calendar and appearance picker.
struct CartoonPanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .stickerPanelBackground(cornerRadius: 22)
    }
}

/// Double shadow + soft blue stroke (matches summary month panel); no extra padding.
struct StickerPanelBackground: ViewModifier {
    var cornerRadius: CGFloat = 22
    var strokeOpacity: Double = 0.15
    var strokeWidth: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(TwelveTheme.surface)
                    .shadow(color: TwelveTheme.primaryBlue.opacity(0.12), radius: 1, x: 3, y: 4)
                    .shadow(color: Color.black.opacity(0.06), radius: 14, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(TwelveTheme.primaryBlue.opacity(strokeOpacity), lineWidth: strokeWidth)
            )
    }
}

extension View {
    func cartoonPanelChrome() -> some View {
        modifier(CartoonPanelChrome())
    }

    func stickerPanelBackground(cornerRadius: CGFloat = 22, strokeOpacity: Double = 0.15, strokeWidth: CGFloat = 2) -> some View {
        modifier(StickerPanelBackground(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity, strokeWidth: strokeWidth))
    }
}
