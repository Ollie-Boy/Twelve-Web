import Foundation

enum LedgerTransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case refund

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .refund: return "Refund"
        }
    }
}
