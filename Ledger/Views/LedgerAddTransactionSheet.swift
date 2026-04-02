import SwiftUI

struct LedgerAddTransactionSheet: View {
    @Binding var isPresented: Bool
    var onSave: (LedgerEntry) -> Void

    @State private var date: Date = Date()
    @State private var isExpense: Bool = true
    @State private var amountText: String = ""
    @State private var category: String = ""
    @State private var note: String = ""

    private var parsedAmount: Decimal? {
        let trimmed = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private var canSave: Bool {
        guard let a = parsedAmount, a > 0 else { return false }
        return !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Text("Type")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Spacer()
                        Picker("", selection: $isExpense) {
                            Text("Expense").tag(true)
                            Text("Income").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("e.g. Food, Transport", text: $category)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 16))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("Optional", text: $note)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .font(TwelveTheme.appFont(size: 16))
                    .tint(TwelveTheme.primaryBlueDark.opacity(0.85))
                }
                .padding(18)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New entry")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .disabled(!canSave)
                }
            }
        }
        .font(TwelveTheme.appFont(size: 16))
    }

    private func save() {
        guard let a = parsedAmount, a > 0 else { return }
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cat.isEmpty else { return }
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = LedgerEntry(
            date: date,
            amount: a,
            isExpense: isExpense,
            category: cat,
            note: n
        )
        onSave(entry)
        isPresented = false
    }
}
