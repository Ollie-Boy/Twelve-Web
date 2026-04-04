import Foundation

/// Writes a tiny snapshot for the widget extension (App Group). If the group is not configured, this no-ops.
enum SharedWidgetData {
    static let appGroupId = "group.com.example.TwelveLedger"

    private static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private enum Keys {
        static let twelveWeather = "widget.v2.twelve.weather"
        static let twelveDate = "widget.v2.twelve.date"
        static let twelveLastTitle = "widget.v2.twelve.lastTitle"
        static let ledgerNet = "widget.v2.ledger.monthNet"
        static let ledgerCurrency = "widget.v2.ledger.currency"
    }

    static func updateTwelveSnapshot(weatherTitle: String, dateSubtitle: String, lastEntryTitle: String?) {
        guard let d = suite else { return }
        d.set(weatherTitle, forKey: Keys.twelveWeather)
        d.set(dateSubtitle, forKey: Keys.twelveDate)
        d.set(lastEntryTitle ?? "", forKey: Keys.twelveLastTitle)
    }

    static func updateLedgerSnapshot(monthNetFormatted: String, currencyCode: String) {
        guard let d = suite else { return }
        d.set(monthNetFormatted, forKey: Keys.ledgerNet)
        d.set(currencyCode, forKey: Keys.ledgerCurrency)
    }
}
