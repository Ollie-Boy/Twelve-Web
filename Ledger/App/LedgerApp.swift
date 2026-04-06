import SwiftUI

@main
struct LedgerApp: App {
    @StateObject private var appearance = AppearanceStore(
        storageKey: "ledgerAppearancePreference",
        legacyStorageKey: nil
    )
    @StateObject private var currency = LedgerCurrencyStore()
    @ObservedObject private var typeRefresh = TypographyRefreshNotifier.shared

    var body: some Scene {
        WindowGroup {
            LedgerRootView()
                .font(TwelveTheme.appFont(size: 16))
                .environmentObject(appearance)
                .environmentObject(currency)
                .preferredColorScheme(appearance.preferredColorScheme)
                .id(typeRefresh.generation)
        }
    }
}
