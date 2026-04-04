import Foundation

enum LedgerWidgetSnapshotReader {
    static func load() -> (net: String, code: String) {
        let d = UserDefaults(suiteName: WidgetSharedConstants.appGroupId)
        return (
            d?.string(forKey: "ledger.monthNet") ?? "—",
            d?.string(forKey: "ledger.currency") ?? ""
        )
    }
}
