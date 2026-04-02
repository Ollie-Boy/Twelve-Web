import Foundation
import SwiftUI

@MainActor
final class LedgerCurrencyStore: ObservableObject {
    private static let key = "ledger.currency.code"

    @Published private(set) var currencyCode: String

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.key), !saved.isEmpty {
            currencyCode = saved
        } else {
            currencyCode = Locale.current.currency?.identifier ?? "USD"
        }
    }

    func setCurrencyCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != currencyCode else { return }
        currencyCode = trimmed.uppercased()
        UserDefaults.standard.set(currencyCode, forKey: Self.key)
    }

    func formatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.locale = Locale.current
        return f
    }

    func format(_ value: Decimal) -> String {
        formatter().string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    /// Common ISO 4217 codes for quick pickers (user can rely on system locale for symbol).
    static let commonCodes: [String] = [
        "USD", "EUR", "GBP", "JPY", "CNY", "HKD", "TWD", "KRW", "INR", "AUD", "CAD", "CHF", "SGD", "SEK", "NOK", "NZD"
    ]
}
