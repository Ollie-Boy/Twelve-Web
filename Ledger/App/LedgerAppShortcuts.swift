import AppIntents
import Foundation

// MARK: - Persist (same key as LedgerStorage)

enum LedgerShortcutPersistence {
    private static let storage = LedgerStorage()

    static func appendEntry(
        amount: Decimal,
        kind: LedgerTransactionKind,
        category: String,
        note: String
    ) {
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cat.isEmpty else { return }
        let amt = LedgerDecimalFormatting.round(max(0, amount))
        guard amt > 0 else { return }
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        var entries = storage.loadEntries()
        let entry = LedgerEntry(
            date: Date(),
            amount: amt,
            kind: kind,
            category: cat,
            note: n
        )
        entries.insert(entry, at: 0)
        storage.saveEntries(entries)
    }

    static func formatMoneyLine(amount: Decimal, kind: LedgerTransactionKind) -> String {
        let code = (UserDefaults.standard.string(forKey: "ledger.currency.code") ?? Locale.current.currency?.identifier ?? "USD")
            .uppercased()
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.locale = Locale.current
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let money = f.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        switch kind {
        case .expense: return "Logged expense \(money)"
        case .income: return "Logged income \(money)"
        }
    }
}

// MARK: - Errors

private enum LedgerIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case emptyCategory

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount: "Enter an amount greater than zero."
        case .emptyCategory: "Category cannot be empty."
        }
    }
}

// MARK: - Intents

struct LogLedgerExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log expense in Ledger"
    static var description = IntentDescription("Adds an expense. Uses the currency you set inside Ledger.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", description: "Positive number, up to 2 decimal places.")
    var amount: Double

    @Parameter(title: "Category", description: "e.g. Food, Transport")
    var category: String

    @Parameter(title: "Note", default: "")
    var note: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) expense for \(\.$category)") {
            \.$note
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let dec = LedgerDecimalFormatting.round(Decimal(amount))
        guard dec > 0 else { throw LedgerIntentError.invalidAmount }
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cat.isEmpty else { throw LedgerIntentError.emptyCategory }

        let line = await MainActor.run {
            LedgerShortcutPersistence.appendEntry(amount: dec, kind: .expense, category: cat, note: note)
            return LedgerShortcutPersistence.formatMoneyLine(amount: dec, kind: .expense)
        }
        return .result(value: line)
    }
}

struct LogLedgerIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log income in Ledger"
    static var description = IntentDescription("Adds income. Uses the currency you set inside Ledger.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", description: "Positive number, up to 2 decimal places.")
    var amount: Double

    @Parameter(title: "Category", description: "e.g. Salary, Gift")
    var category: String

    @Parameter(title: "Note", default: "")
    var note: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) income for \(\.$category)") {
            \.$note
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let dec = LedgerDecimalFormatting.round(Decimal(amount))
        guard dec > 0 else { throw LedgerIntentError.invalidAmount }
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cat.isEmpty else { throw LedgerIntentError.emptyCategory }

        let line = await MainActor.run {
            LedgerShortcutPersistence.appendEntry(amount: dec, kind: .income, category: cat, note: note)
            return LedgerShortcutPersistence.formatMoneyLine(amount: dec, kind: .income)
        }
        return .result(value: line)
    }
}

struct OpenLedgerAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Ledger"
    static var description = IntentDescription("Opens Ledger.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Suggested shortcuts (Shortcuts app + Siri)

struct LedgerAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: LogLedgerExpenseIntent(),
                phrases: [
                    "Log an expense in \(.applicationName)",
                    "Add expense with \(.applicationName)",
                    "Record spending in \(.applicationName)",
                    "在\(.applicationName)记一笔支出",
                    "用\(.applicationName)记账支出"
                ],
                shortTitle: "Log expense",
                systemImageName: "minus.circle"
            ),
            AppShortcut(
                intent: LogLedgerIncomeIntent(),
                phrases: [
                    "Log income in \(.applicationName)",
                    "Add income with \(.applicationName)",
                    "在\(.applicationName)记一笔收入",
                    "用\(.applicationName)记账收入"
                ],
                shortTitle: "Log income",
                systemImageName: "plus.circle"
            ),
            AppShortcut(
                intent: OpenLedgerAppIntent(),
                phrases: [
                    "Open \(.applicationName)",
                    "Show \(.applicationName)",
                    "打开\(.applicationName)"
                ],
                shortTitle: "Open Ledger",
                systemImageName: "wallet.pass"
            )
        ]
    }

    /// Call when the main screen appears so Shortcuts can index the app (`.task` on launch alone is sometimes too early).
    static func registerWithSystem() {
        Task {
            await updateAppShortcutParameters()
        }
    }
}
