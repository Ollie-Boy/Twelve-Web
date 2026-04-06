import SwiftUI

struct LedgerMonthReviewSheet: View {
    let monthStart: Date
    let bookId: String
    let entries: [LedgerEntry]
    let formatMoney: (Decimal) -> String
    /// Signed amount in report currency (income +, expense −).
    var signedAmountInReport: (LedgerEntry) -> Decimal = { $0.signedNetAmount }
    @Environment(\.dismiss) private var dismiss

    private var cal: Calendar { Calendar.current }

    private var monthEntries: [LedgerEntry] {
        entries.filter { e in
            e.bookId == bookId && cal.isDate(e.date, equalTo: monthStart, toGranularity: .month)
        }
    }

    private var income: Decimal {
        LedgerDecimalFormatting.round(
            monthEntries.filter { $0.kind == .income }.reduce(0) { $0 + signedAmountInReport($1) }
        )
    }

    private var expense: Decimal {
        LedgerDecimalFormatting.round(
            monthEntries.filter { $0.kind == .expense }.reduce(0) { $0 - signedAmountInReport($1) }
        )
    }

    private var net: Decimal {
        LedgerDecimalFormatting.round(monthEntries.reduce(0) { $0 + signedAmountInReport($1) })
    }

    private var topExpenseCategories: [(String, Decimal)] {
        var map: [String: Decimal] = [:]
        for e in monthEntries where e.kind == .expense {
            let c = e.category.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = c.isEmpty ? "Uncategorized" : c
            map[key, default: 0] += -signedAmountInReport(e)
        }
        return map.map { ($0.key, LedgerDecimalFormatting.round($0.value)) }
            .sorted { ($0.1 as NSDecimalNumber).doubleValue > ($1.1 as NSDecimalNumber).doubleValue }
            .prefix(5)
            .map { $0 }
    }

    private var largestExpense: LedgerEntry? {
        monthEntries
            .filter { $0.kind == .expense }
            .max(by: { -signedAmountInReport($0) < -signedAmountInReport($1) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(monthStart.formatted(.dateTime.month(.wide).year()))
                        .font(TwelveTheme.appFont(size: 20, weight: .bold))
                        .foregroundStyle(TwelveTheme.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        row("Entries", "\(monthEntries.count)")
                        row("Income", formatMoney(income))
                        row("Spending", formatMoney(expense))
                        row("Net", formatMoney(net))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if !topExpenseCategories.isEmpty {
                        Text("Top spending categories")
                            .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(topExpenseCategories, id: \.0) { name, amt in
                                HStack {
                                    Text(name)
                                        .font(TwelveTheme.appFont(size: 15))
                                    Spacer()
                                    Text(formatMoney(amt))
                                        .font(TwelveTheme.appFont(size: 15))
                                        .foregroundStyle(TwelveTheme.textSecondary)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if let big = largestExpense {
                        Text("Largest expense")
                            .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(big.category)
                                .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                            Text(formatMoney(-signedAmountInReport(big)))
                                .font(TwelveTheme.appFont(size: 15))
                                .foregroundStyle(TwelveTheme.primaryBlueDark)
                            if !big.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(big.note)
                                    .font(TwelveTheme.appFont(size: 13))
                                    .foregroundStyle(TwelveTheme.textTertiary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if monthEntries.isEmpty {
                        Text("No transactions in this month.")
                            .font(TwelveTheme.appFont(size: 14))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                }
                .padding(20)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Month review")
                        .font(TwelveTheme.Settings.navigationTitle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.Settings.navigationDone)
                }
            }
        }
        .font(TwelveTheme.Settings.rootBody)
        .presentationDetents([.medium, .large])
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(TwelveTheme.appFont(size: 15))
            Spacer()
            Text(v).font(TwelveTheme.appFont(size: 15)).foregroundStyle(TwelveTheme.textSecondary)
        }
    }
}
