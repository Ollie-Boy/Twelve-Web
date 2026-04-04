import Foundation

/// Writes a tiny snapshot for the widget extension (App Group). If the group is not configured, this no-ops.
enum SharedWidgetData {
    static let appGroupId = "group.com.example.TwelveLedger"

    private static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func updateTwelveSnapshot(weatherTitle: String, dateSubtitle: String, lastEntryTitle: String?) {
        guard let d = suite else { return }
        d.set(weatherTitle, forKey: "twelve.weather")
        d.set(dateSubtitle, forKey: "twelve.date")
        d.set(lastEntryTitle ?? "", forKey: "twelve.lastTitle")
    }

    static func updateLedgerSnapshot(monthNetFormatted: String, currencyCode: String) {
        guard let d = suite else { return }
        d.set(monthNetFormatted, forKey: "ledger.monthNet")
        d.set(currencyCode, forKey: "ledger.currency")
    }
}
