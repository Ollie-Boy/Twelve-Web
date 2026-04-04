import SwiftUI
import UIKit

struct LedgerSettingsSheet: View {
    @ObservedObject var bookStore: LedgerBookStore
    @Binding var entries: [LedgerEntry]
    @ObservedObject var currency: LedgerCurrencyStore
    var storage: LedgerStorage
    var onDismissReload: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var categories: [String] = []
    @State private var budgets: [LedgerBudget] = []
    @State private var recurring: [LedgerRecurringTemplate] = []
    @State private var iCloudOn = ICloudDataMirror.ledgerEnabled
    @State private var newBookName = ""
    @State private var showAddBook = false
    @State private var budgetCategory = ""
    @State private var budgetCap = ""
    @State private var recAmount = ""
    @State private var recCategory = ""
    @State private var recDay = "1"
    @State private var recKind: LedgerTransactionKind = .expense
    @State private var csvPayload: CSVExportItem?

    private var cal: Calendar { Calendar.current }

    private var monthNow: (y: Int, m: Int) {
        let d = Date()
        (cal.component(.year, from: d), cal.component(.month, from: d))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    booksSection
                    iCloudSection
                    categoriesSection
                    budgetsSection
                    recurringSection
                    exportSection
                }
                .padding(16)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ledger settings")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onDismissReload()
                    }
                    .font(TwelveTheme.appFont(size: 17))
                }
            }
            .onAppear { reloadLocalState() }
            .alert("New book", isPresented: $showAddBook) {
                TextField("Name", text: $newBookName)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    bookStore.addBook(name: newBookName)
                    newBookName = ""
                }
            } message: {
                Text("Separate transactions by purpose (e.g. Travel).")
            }
            .sheet(item: $csvPayload) { item in
                ActivityView(activityItems: [item.url])
            }
        }
        .font(TwelveTheme.appFont(size: 16))
        .presentationDetents([.large])
    }

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Books")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            Picker("Active book", selection: $bookStore.activeBookId) {
                ForEach(bookStore.books) { b in
                    Text(b.name).tag(b.id)
                }
            }
            .pickerStyle(.menu)
            Button("Add book…") { showAddBook = true }
                .font(TwelveTheme.appFont(size: 15, weight: .medium))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var iCloudSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iCloud backup (optional)")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            Toggle("Mirror data to iCloud Documents", isOn: $iCloudOn)
                .tint(TwelveTheme.primaryBlue)
                .onChange(of: iCloudOn) { _, v in
                    ICloudDataMirror.ledgerEnabled = v
                    if v, let data = try? JSONEncoder().encode(entries) {
                        ICloudDataMirror.mirrorLedgerJSON(data)
                    }
                }
            Text(ICloudDataMirror.ledgerMirrorStatusLine())
                .font(TwelveTheme.appFont(size: 12))
                .foregroundStyle(TwelveTheme.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category shortcuts")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            ForEach(categories, id: \.self) { c in
                HStack {
                    Text(c).font(TwelveTheme.appFont(size: 15))
                    Spacer()
                    Button("Remove", role: .destructive) {
                        categories.removeAll { $0 == c }
                        LedgerCategoryStore.save(categories, for: bookStore.activeBookId)
                    }
                    .font(TwelveTheme.appFont(size: 14))
                }
            }
            Text("Categories are suggested when you add entries; removing does not delete past rows.")
                .font(TwelveTheme.appFont(size: 11))
                .foregroundStyle(TwelveTheme.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var budgetsSection: some View {
        let y = monthNow.y
        let m = monthNow.m
        return VStack(alignment: .leading, spacing: 10) {
            Text("Monthly budgets (expenses)")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            ForEach(budgets.filter { $0.bookId == bookStore.activeBookId && $0.year == y && $0.month == m }) { b in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.category)
                            .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                        let spent = LedgerBudgetStore.spent(for: b.category, bookId: bookStore.activeBookId, year: y, month: m, entries: entries)
                        Text("\(currency.format(spent)) / \(currency.format(b.capAmount))")
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    Spacer()
                    Button("Remove", role: .destructive) {
                        var all = LedgerBudgetStore.load()
                        all.removeAll { $0.id == b.id }
                        LedgerBudgetStore.save(all)
                        reloadLocalState()
                    }
                }
            }
            HStack {
                TextField("Category", text: $budgetCategory)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                TextField("Cap", text: $budgetCap)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .frame(width: 88)
                    .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button("Add") {
                    let cat = budgetCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let cap = LedgerDecimalFormatting.parseAmount(from: budgetCap), cap > 0, !cat.isEmpty else { return }
                    var all = LedgerBudgetStore.load()
                    all.append(LedgerBudget(bookId: bookStore.activeBookId, year: y, month: m, category: cat, capAmount: cap))
                    LedgerBudgetStore.save(all)
                    budgetCategory = ""
                    budgetCap = ""
                    reloadLocalState()
                }
                .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recurring templates")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            ForEach(recurring.filter { $0.bookId == bookStore.activeBookId }) { t in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.category)
                            .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                        Text("\(t.kind.title) · day \(t.dayOfMonth) · \(currency.format(t.amount))")
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    Spacer()
                    Button("Add now") {
                        postTemplate(t)
                    }
                    .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.surfaceTintBlue))
                    Button(role: .destructive) {
                        var all = LedgerRecurringStore.load()
                        all.removeAll { $0.id == t.id }
                        LedgerRecurringStore.save(all)
                        reloadLocalState()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            HStack {
                TextField("Amount", text: $recAmount)
                    .keyboardType(.decimalPad)
                    .frame(width: 72)
                Picker("", selection: $recKind) {
                    Text("Expense").tag(LedgerTransactionKind.expense)
                    Text("Income").tag(LedgerTransactionKind.income)
                }
                .pickerStyle(.segmented)
            }
            TextField("Category", text: $recCategory)
                .textFieldStyle(.plain)
                .padding(10)
                .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            HStack {
                TextField("Day 1–28", text: $recDay)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                Button("Save template") {
                    guard let a = LedgerDecimalFormatting.parseAmount(from: recAmount), a > 0 else { return }
                    let cat = recCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cat.isEmpty else { return }
                    let day = Int(recDay) ?? 1
                    var all = LedgerRecurringStore.load()
                    all.append(LedgerRecurringTemplate(bookId: bookStore.activeBookId, amount: a, kind: recKind, category: cat, dayOfMonth: day))
                    LedgerRecurringStore.save(all)
                    recAmount = ""
                    recCategory = ""
                    recDay = "1"
                    reloadLocalState()
                }
                .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            Button {
                let bookName = bookStore.books.first(where: { $0.id == bookStore.activeBookId })?.name ?? "Ledger"
                let filtered = entries.filter { $0.bookId == bookStore.activeBookId }
                let csv = LedgerCSVExport.csvString(entries: filtered, bookName: bookName)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(LedgerCSVExport.filename())
                try? csv.data(using: .utf8)?.write(to: url)
                csvPayload = CSVExportItem(url: url)
            } label: {
                Label("Export this book as CSV", systemImage: "square.and.arrow.up")
                    .font(TwelveTheme.appFont(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reloadLocalState() {
        categories = LedgerCategoryStore.load(for: bookStore.activeBookId)
        budgets = LedgerBudgetStore.load()
        recurring = LedgerRecurringStore.load()
        iCloudOn = ICloudDataMirror.ledgerEnabled
    }

    private func postTemplate(_ t: LedgerRecurringTemplate) {
        let y = cal.component(.year, from: Date())
        let m = cal.component(.month, from: Date())
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = min(t.dayOfMonth, cal.range(of: .day, in: .month, for: Date())?.count ?? 28)
        comps.hour = 12
        let date = cal.date(from: comps) ?? Date()
        let entry = LedgerEntry(
            bookId: t.bookId,
            date: date,
            amount: t.amount,
            kind: t.kind,
            category: t.category,
            note: t.note
        )
        entries.insert(entry, at: 0)
        storage.saveEntries(entries)
    }
}

private struct CSVExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
