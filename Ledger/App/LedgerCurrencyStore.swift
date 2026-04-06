import Foundation
import SwiftUI

@MainActor
final class LedgerCurrencyStore: ObservableObject {
    private static let key = "ledger.currency.code"
    private static let reportKey = "ledger.report.currency.code"
    private static let manualRatesKey = "ledger.fx.manualRates.v1"

    @Published private(set) var currencyCode: String
    @Published private(set) var reportCurrencyCode: String

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.key), !saved.isEmpty {
            currencyCode = saved
        } else {
            currencyCode = Locale.current.currency?.identifier ?? "USD"
        }
        if let r = UserDefaults.standard.string(forKey: Self.reportKey), !r.isEmpty {
            reportCurrencyCode = r.uppercased()
        } else {
            reportCurrencyCode = currencyCode
        }
    }

    func setCurrencyCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != currencyCode else { return }
        currencyCode = trimmed.uppercased()
        UserDefaults.standard.set(currencyCode, forKey: Self.key)
    }

    func setReportCurrencyCode(_ code: String) {
        let t = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !t.isEmpty else { return }
        reportCurrencyCode = t
        UserDefaults.standard.set(reportCurrencyCode, forKey: Self.reportKey)
    }

    /// Manual overrides: from ISO → rate to report currency (multiply amount in `from` by rate → report).
    func manualRate(from: String, to report: String) -> Decimal? {
        let f = from.uppercased()
        let r = report.uppercased()
        guard f != r else { return 1 }
        guard let data = UserDefaults.standard.data(forKey: Self.manualRatesKey),
              let map = try? JSONDecoder().decode([String: String].self, from: data),
              let s = map["\(f)->\(r)"],
              let d = Decimal(string: s) else { return nil }
        return d > 0 ? LedgerDecimalFormatting.round(d, scale: 6) : nil
    }

    func setManualRate(from: String, to report: String, rateText: String) {
        let f = from.uppercased()
        let r = report.uppercased()
        var map: [String: String] = [:]
        if let data = UserDefaults.standard.data(forKey: Self.manualRatesKey),
           let existing = try? JSONDecoder().decode([String: String].self, from: data) {
            map = existing
        }
        let key = "\(f)->\(r)"
        let t = rateText.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || f == r {
            map.removeValue(forKey: key)
        } else if let d = Decimal(string: t.replacingOccurrences(of: ",", with: ".")), d > 0 {
            map[key] = "\(d)"
        }
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: Self.manualRatesKey)
        }
    }

    func formatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.locale = Locale.current
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }

    func format(_ value: Decimal) -> String {
        formatter().string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    func format(_ value: Decimal, currencyCode code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.locale = Locale.current
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    func formatReport(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = reportCurrencyCode
        f.locale = Locale.current
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    /// Common ISO 4217 codes for quick pickers (user can rely on system locale for symbol).
    static let commonCodes: [String] = [
        "USD", "EUR", "GBP", "JPY", "CNY", "HKD", "TWD", "KRW", "INR", "AUD", "CAD", "CHF", "SGD", "SEK", "NOK", "NZD"
    ]
}
