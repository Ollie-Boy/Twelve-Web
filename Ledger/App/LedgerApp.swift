import SwiftUI

@main
struct LedgerApp: App {
    @StateObject private var appearance = AppearanceStore(
        storageKey: "ledgerAppearancePreference",
        legacyStorageKey: nil
    )

    var body: some Scene {
        WindowGroup {
            LedgerRootView()
                .font(TwelveTheme.handwrittenFont(size: 16))
                .environmentObject(appearance)
                .preferredColorScheme(appearance.preferredColorScheme)
        }
    }
}
