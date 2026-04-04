import Foundation

struct LedgerRecurringTemplate: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var bookId: String
    var amount: Decimal
    var kind: LedgerTransactionKind
    var category: String
    var note: String
    /// 1...28 recommended for safety across months.
    var dayOfMonth: Int

    init(
        id: UUID = UUID(),
        bookId: String,
        amount: Decimal,
        kind: LedgerTransactionKind,
        category: String,
        note: String = "",
        dayOfMonth: Int
    ) {
        self.id = id
        self.bookId = bookId
        self.amount = LedgerDecimalFormatting.round(max(0, amount))
        self.kind = kind
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.dayOfMonth = min(28, max(1, dayOfMonth))
    }
}

enum LedgerRecurringStore {
    private static let key = "ledger.recurring.v1"

    static func load() -> [LedgerRecurringTemplate] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([LedgerRecurringTemplate].self, from: data) else { return [] }
        return list
    }

    static func save(_ list: [LedgerRecurringTemplate]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func templates(for bookId: String) -> [LedgerRecurringTemplate] {
        load().filter { $0.bookId == bookId }
    }
}
