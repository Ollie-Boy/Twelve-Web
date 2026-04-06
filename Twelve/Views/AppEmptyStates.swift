import SwiftUI

struct DiaryEmptyStateView: View {
    let onCompose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "book.pages")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(TwelveTheme.primaryBlue.opacity(0.85))
            Text("No pages yet")
                .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                .foregroundStyle(TwelveTheme.textPrimary)
            Text("Tap the + button to write your first entry. The wind’s quiet — room for a story.")
                .font(TwelveTheme.appFont(size: 15))
                .foregroundStyle(TwelveTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Start writing") {
                onCompose()
            }
            .buttonStyle(TwelvePrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .stickerPanelBackground(cornerRadius: 20)
    }
}

struct LedgerEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(TwelveTheme.primaryBlue.opacity(0.85))
            Text("No entries yet")
                .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                .foregroundStyle(TwelveTheme.textPrimary)
            Text("Tap + to log spending or income. Keep it light — one line at a time.")
                .font(TwelveTheme.appFont(size: 15))
                .foregroundStyle(TwelveTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Add transaction") {
                onAdd()
            }
            .buttonStyle(TwelvePrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .stickerPanelBackground(cornerRadius: 20)
    }
}
