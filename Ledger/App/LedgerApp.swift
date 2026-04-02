import SwiftUI

@main
struct LedgerApp: App {
    @StateObject private var appearance = AppearanceStore(
        storageKey: "ledgerAppearancePreference",
        legacyStorageKey: nil
    )
    @StateObject private var currency = LedgerCurrencyStore()

    var body: some Scene {
        WindowGroup {
            LedgerRootView()
                .font(TwelveTheme.handwrittenFont(size: 16))
                .environmentObject(appearance)
                .environmentObject(currency)
                .preferredColorScheme(appearance.preferredColorScheme)
        }
    }
}
