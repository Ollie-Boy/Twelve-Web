import Foundation

struct LedgerEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    /// Always stored as a non-negative magnitude; use `isExpense` for sign in summaries.
    var amount: Decimal
    var isExpense: Bool
    var category: String
    var note: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        isExpense: Bool,
        category: String,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.amount = max(0, amount)
        self.isExpense = isExpense
        self.category = category
        self.note = note
    }

    /// Signed amount: negative for expenses, positive for income.
    var signedAmount: Decimal {
        isExpense ? -amount : amount
    }
}
