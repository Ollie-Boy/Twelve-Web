import Foundation

/// Monthly spending cap for a category (expense net sum compared against cap).
struct LedgerBudget: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var bookId: String
    /// When `repeatsEveryMonth` is true, `year`/`month` are ignored for matching.
    var year: Int
    var month: Int
    var category: String
    var capAmount: Decimal
    /// Same cap applies to every calendar month (natural month rollover on the main screen).
    var repeatsEveryMonth: Bool

    init(
        id: UUID = UUID(),
        bookId: String,
        year: Int,
        month: Int,
        category: String,
        capAmount: Decimal,
        repeatsEveryMonth: Bool = false
    ) {
        self.id = id
        self.bookId = bookId
        self.year = year
        self.month = month
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self.capAmount = LedgerDecimalFormatting.round(max(0, capAmount))
        self.repeatsEveryMonth = repeatsEveryMonth
    }

    enum CodingKeys: String, CodingKey {
        case id, bookId, year, month, category, capAmount, repeatsEveryMonth
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        bookId = try c.decode(String.self, forKey: .bookId)
        year = try c.decode(Int.self, forKey: .year)
        month = try c.decode(Int.self, forKey: .month)
        category = try c.decode(String.self, forKey: .category)
        capAmount = try c.decode(Decimal.self, forKey: .capAmount)
        repeatsEveryMonth = try c.decodeIfPresent(Bool.self, forKey: .repeatsEveryMonth) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(bookId, forKey: .bookId)
        try c.encode(year, forKey: .year)
        try c.encode(month, forKey: .month)
        try c.encode(category, forKey: .category)
        try c.encode(capAmount, forKey: .capAmount)
        try c.encode(repeatsEveryMonth, forKey: .repeatsEveryMonth)
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

    /// Budget lines that apply to this calendar month: repeating caps plus one-off rows for this month (one-off wins on same category).
    static func budgets(for bookId: String, year: Int, month: Int) -> [LedgerBudget] {
        let all = load()
        let repeating = all.filter { $0.bookId == bookId && $0.repeatsEveryMonth }
        let oneOff = all.filter { $0.bookId == bookId && !$0.repeatsEveryMonth && $0.year == year && $0.month == month }
        var byCategory: [String: LedgerBudget] = [:]
        for b in repeating {
            byCategory[b.category] = b
        }
        for b in oneOff {
            byCategory[b.category] = b
        }
        return byCategory.values.sorted {
            $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending
        }
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
