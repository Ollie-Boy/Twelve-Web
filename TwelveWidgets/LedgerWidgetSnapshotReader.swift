import Foundation

enum LedgerWidgetSnapshotReader {
    static func load() -> (net: String, code: String) {
        let d = UserDefaults(suiteName: WidgetSharedConstants.appGroupId)
        func s(_ k: String, _ legacy: String) -> String? {
            if let v = d?.string(forKey: k), !v.isEmpty { return v }
            return d?.string(forKey: legacy)
        }
        let net = s("widget.v2.ledger.monthNet", "ledger.monthNet") ?? "—"
        let code = s("widget.v2.ledger.currency", "ledger.currency") ?? ""
        return (net, code)
    }
}
