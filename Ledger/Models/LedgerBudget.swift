import Foundation

/// Monthly spending cap for a category (expense net sum compared against cap).
struct LedgerBudget: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var bookId: String
    /// Calendar year.
    var year: Int
    var month: Int
    var category: String
    var capAmount: Decimal

    init(
        id: UUID = UUID(),
        bookId: String,
        year: Int,
        month: Int,
        category: String,
        capAmount: Decimal
    ) {
        self.id = id
        self.bookId = bookId
        self.year = year
        self.month = month
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self.capAmount = LedgerDecimalFormatting.round(max(0, capAmount))
    }
}

enum LedgerBudgetStore {
    private static let key = "ledger.budgets.v1"

    static func load() -> [LedgerBudget] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([LedgerBudget].self, from: data) else { return [] }
        return list
    }

    static func save(_ list: [LedgerBudget]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func budgets(for bookId: String, year: Int, month: Int) -> [LedgerBudget] {
        load().filter { $0.bookId == bookId && $0.year == year && $0.month == month }
    }

    static func spent(for category: String, bookId: String, year: Int, month: Int, entries: [LedgerEntry]) -> Decimal {
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let cal = Calendar.current
        return entries.reduce(Decimal(0)) { sum, e in
            guard e.bookId == bookId, e.kind == .expense else { return sum }
            let y = cal.component(.year, from: e.date)
            let m = cal.component(.month, from: e.date)
            guard y == year, m == month else { return sum }
            guard e.category.trimmingCharacters(in: .whitespacesAndNewlines) == cat else { return sum }
            return sum + e.netAmount
        }
    }
}
