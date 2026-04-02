import Foundation

struct LedgerEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    /// Gross amount (always non-negative), stored with 2-decimal precision.
    var amount: Decimal
    var kind: LedgerTransactionKind
    /// Refunds applied to this line (e.g. expense 100 + refund 20 → net expense 80).
    var refundTotal: Decimal
    var category: String
    var note: String
    var location: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        kind: LedgerTransactionKind,
        refundTotal: Decimal = 0,
        category: String,
        note: String = "",
        location: String? = nil
    ) {
        self.id = id
        self.date = date
        let a = LedgerDecimalFormatting.round(max(0, amount))
        self.amount = a
        let r = LedgerDecimalFormatting.round(max(0, refundTotal))
        self.refundTotal = min(r, a)
        self.kind = kind
        self.category = category
        self.note = note
        self.location = location
    }

    /// Net magnitude after refunds (≥ 0).
    var netAmount: Decimal {
        let r = min(refundTotal, amount)
        return LedgerDecimalFormatting.round(max(0, amount - r))
    }

    /// For monthly totals: expense negative, income positive.
    var signedNetAmount: Decimal {
        switch kind {
        case .expense: return -netAmount
        case .income: return netAmount
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, amount, kind, category, note
        case isExpense
        case refundTotal
        case location
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        var decodedAmount = LedgerDecimalFormatting.round(max(0, try c.decode(Decimal.self, forKey: .amount)))
        category = try c.decode(String.self, forKey: .category)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        location = try c.decodeIfPresent(String.self, forKey: .location)

        if let kindStr = try c.decodeIfPresent(String.self, forKey: .kind) {
            switch kindStr {
            case LedgerTransactionKind.expense.rawValue:
                kind = .expense
            case LedgerTransactionKind.income.rawValue:
                kind = .income
            case "refund":
                // Legacy standalone refund row → income
                kind = .income
            default:
                kind = .expense
            }
        } else if let exp = try c.decodeIfPresent(Bool.self, forKey: .isExpense) {
            kind = exp ? .expense : .income
        } else {
            kind = .expense
        }

        var rt = try c.decodeIfPresent(Decimal.self, forKey: .refundTotal) ?? 0
        rt = LedgerDecimalFormatting.round(max(0, rt))
        amount = decodedAmount
        refundTotal = min(rt, amount)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(amount, forKey: .amount)
        try c.encode(kind, forKey: .kind)
        try c.encode(refundTotal, forKey: .refundTotal)
        try c.encode(category, forKey: .category)
        try c.encode(note, forKey: .note)
        try c.encodeIfPresent(location, forKey: .location)
    }
}
