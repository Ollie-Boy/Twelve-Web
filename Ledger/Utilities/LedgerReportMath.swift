import Foundation

enum LedgerReportMath {
    /// Converts signed net to report currency using manual map only; falls back to raw amount if no rate.
    static func signedNetInReportCurrency(
        entry: LedgerEntry,
        bookCurrency: String,
        reportCurrency: String,
        manualRate: (String, String) -> Decimal?
    ) -> Decimal {
        let line = (entry.currencyCode ?? bookCurrency).uppercased()
        let report = reportCurrency.uppercased()
        let amt = entry.signedNetAmount
        if line == report { return LedgerDecimalFormatting.round(amt) }
        if let m = manualRate(line, report) {
            return LedgerDecimalFormatting.round(amt * m)
        }
        return LedgerDecimalFormatting.round(amt)
    }
}
