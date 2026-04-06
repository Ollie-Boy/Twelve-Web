import Foundation

struct LedgerFixedExpense: Identifiable, Codable, Equatable {
    let id: String
    var bookId: String
    var title: String
    /// 1...28
    var dayOfMonth: Int
    var note: String

    init(id: String = UUID().uuidString, bookId: String, title: String, dayOfMonth: Int, note: String = "") {
        self.id = id
        self.bookId = bookId
        self.title = title
        self.dayOfMonth = min(28, max(1, dayOfMonth))
        self.note = note
    }
}

enum LedgerFixedExpenseStore {
    private static let key = "ledger.fixedExpenses.v1"

    static func load() -> [LedgerFixedExpense] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([LedgerFixedExpense].self, from: data) else { return [] }
        return list
    }

    static func save(_ list: [LedgerFixedExpense]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
