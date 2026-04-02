import SwiftUI

/// Shared sticker-style panel used by the cartoon calendar and appearance picker.
struct CartoonPanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(TwelveTheme.surface)
                    .shadow(color: TwelveTheme.primaryBlue.opacity(0.12), radius: 1, x: 3, y: 4)
                    .shadow(color: Color.black.opacity(0.06), radius: 14, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(TwelveTheme.primaryBlue.opacity(0.15), lineWidth: 2)
            )
    }
}

extension View {
    func cartoonPanelChrome() -> some View {
        modifier(CartoonPanelChrome())
    }
}
