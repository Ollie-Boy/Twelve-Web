import Foundation

/// ECB rates via Frankfurter (free, no key). Falls back to nil on network/format errors.
enum LedgerFXService {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 12
        return URLSession(configuration: c)
    }()

    struct FrankfurterResponse: Decodable {
        let rates: [String: Double]
    }

    /// Units of `from` per one unit of `to` is NOT what we need — we need: 1 `from` = ? `to`.
    /// API: GET /{date}?from=FROM&to=TO returns `rates: { TO: number }` meaning 1 FROM = rate TO.
    static func rate(from: String, to: String, on date: Date) async -> Decimal? {
        let f = from.uppercased()
        let t = to.uppercased()
        if f == t { return 1 }
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        let path = String(format: "%04d-%02d-%02d", y, m, d)
        guard let url = URL(string: "https://api.frankfurter.app/\(path)?from=\(f)&to=\(t)") else { return nil }
        do {
            let (data, resp) = try await session.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let dec = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
            guard let v = dec.rates[t] else { return nil }
            return LedgerDecimalFormatting.round(Decimal(v), scale: 6)
        } catch {
            return nil
        }
    }
}

enum LedgerMoneyConversion {
    /// Convert `amount` in `lineCurrency` to `reportCurrency` using manual map, then ECB rate for `asOf` date.
    static func convert(
        amount: Decimal,
        lineCurrency: String,
        reportCurrency: String,
        asOf date: Date,
        manualRate: (String, String) -> Decimal?
    ) async -> Decimal {
        let lc = lineCurrency.uppercased()
        let rc = reportCurrency.uppercased()
        if lc == rc { return LedgerDecimalFormatting.round(amount) }
        if let m = manualRate(lc, rc) {
            return LedgerDecimalFormatting.round(amount * m)
        }
        if let r = await LedgerFXService.rate(from: lc, to: rc, on: date) {
            return LedgerDecimalFormatting.round(amount * r)
        }
        return LedgerDecimalFormatting.round(amount)
    }
}
