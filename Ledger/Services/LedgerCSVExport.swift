import Foundation

enum LedgerCSVExport {
    static func csvString(entries: [LedgerEntry], bookName: String) -> String {
        var lines = ["Book,\"\(escape(bookName))\"", "Date,Kind,Category,Amount,Refund,Currency,Note,Location"]
        let sorted = entries.sorted { $0.date > $1.date }
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime]
        for e in sorted {
            let kind = e.kind == .expense ? "expense" : "income"
            let row = [
                df.string(from: e.date) ?? "",
                kind,
                escape(e.category),
                "\(e.amount)",
                "\(e.refundTotal)",
                escape(e.currencyCode ?? ""),
                escape(e.note),
                escape(e.location ?? "")
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        let needs = s.contains(",") || s.contains("\"") || s.contains("\n")
        if !needs { return s }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func filename() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "Ledger-export-\(f.string(from: Date())).csv"
    }
}
