import Foundation

struct LedgerEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    /// Always non-negative.
    var amount: Decimal
    var kind: LedgerTransactionKind
    var category: String
    var note: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        kind: LedgerTransactionKind,
        category: String,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.amount = max(0, amount)
        self.kind = kind
        self.category = category
        self.note = note
    }

    /// Signed for net math: expenses negative; income and refunds positive.
    var signedAmount: Decimal {
        switch kind {
        case .expense: return -amount
        case .income, .refund: return amount
        }
    }

    // MARK: - Migration from v1 (isExpense: Bool)

    enum CodingKeys: String, CodingKey {
        case id, date, amount, kind, category, note
        case isExpense
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        amount = try c.decode(Decimal.self, forKey: .amount)
        category = try c.decode(String.self, forKey: .category)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        if let k = try c.decodeIfPresent(LedgerTransactionKind.self, forKey: .kind) {
            kind = k
        } else if let exp = try c.decodeIfPresent(Bool.self, forKey: .isExpense) {
            kind = exp ? .expense : .income
        } else {
            kind = .expense
        }
        amount = max(0, amount)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(amount, forKey: .amount)
        try c.encode(kind, forKey: .kind)
        try c.encode(category, forKey: .category)
        try c.encode(note, forKey: .note)
    }
}
