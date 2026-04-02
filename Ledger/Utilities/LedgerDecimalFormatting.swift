import Foundation

enum LedgerDecimalFormatting {
    private static let posix = Locale(identifier: "en_US_POSIX")

    /// Bankers rounding to `scale` decimal places (default 2).
    static func round(_ value: Decimal, scale: Int = 2) -> Decimal {
        var v = value
        var result = Decimal()
        NSDecimalRound(&result, &v, scale, .bankers)
        return result
    }

    static func parseAmount(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let d = Decimal(string: normalized, locale: posix) else { return nil }
        return round(max(0, d))
    }

    /// String for TextField: up to 2 fraction digits while typing.
    static func sanitizeAmountInput(_ text: String) -> String {
        var s = text.replacingOccurrences(of: ",", with: ".")
        let allowed = CharacterSet(charactersIn: "0123456789.")
        s = String(s.unicodeScalars.filter { allowed.contains(UnicodeScalar($0.value)!) })
        if let firstDot = s.firstIndex(of: ".") {
            let intPart = String(s[..<firstDot])
            let after = s[s.index(after: firstDot)...]
            let frac = String(after).filter { $0 != "." }
            let frac2 = String(frac.prefix(2))
            if after.isEmpty { return intPart + "." }
            return intPart + "." + frac2
        }
        return s
    }

    static func displayString(for value: Decimal, minFractionDigits: Int = 0, maxFractionDigits: Int = 2) -> String {
        let f = NumberFormatter()
        f.locale = posix
        f.numberStyle = .decimal
        f.minimumFractionDigits = minFractionDigits
        f.maximumFractionDigits = maxFractionDigits
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
