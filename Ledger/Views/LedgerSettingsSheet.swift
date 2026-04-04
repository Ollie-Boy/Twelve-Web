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
    @State private var recurring: [LedgerRecurringTemplate] = []
    @State private var iCloudOn = ICloudDataMirror.ledgerEnabled
    @State private var newBookName = ""
    @State private var showAddBook = false
    @State private var budgetCategory = ""
    @State private var budgetCap = ""
    @State private var budgetRepeatsMonthly = true
    @State private var recAmount = ""
    @State private var recCategory = ""
    @State private var recDay = "1"
    @State private var recKind: LedgerTransactionKind = .expense
    @State private var csvPayload: CSVExportItem?
    @State private var newCategoryShortcut = ""

    private var cal: Calendar { Calendar.current }

    private var monthNow: (y: Int, m: Int) {
        let d = Date()
        return (cal.component(.year, from: d), cal.component(.month, from: d))
    }

    private var activeBookName: String {
        bookStore.books.first(where: { $0.id == bookStore.activeBookId })?.name ?? "—"
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
                        .font(TwelveTheme.Settings.navigationTitle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onDismissReload()
                    }
                    .font(TwelveTheme.Settings.navigationDone)
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
        .font(TwelveTheme.Settings.rootBody)
        .presentationDetents([.large])
    }

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Books")
                .font(TwelveTheme.Settings.sectionHeader)
                .foregroundStyle(TwelveTheme.textSecondary)
            Menu {
                ForEach(bookStore.books) { b in
                    Button {
                        bookStore.activeBookId = b.id
                    } label: {
                        HStack {
                            Text(b.name)
                            if b.id == bookStore.activeBookId {
                                Spacer(minLength: 8)
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(activeBookName)
                        .font(TwelveTheme.Settings.rowPrimary)
                        .foregroundStyle(TwelveTheme.textPrimary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(TwelveTheme.appFont(size: 11))
                        .foregroundStyle(TwelveTheme.textTertiary)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Active book")
            .accessibilityValue(activeBookName)
            Button("Add book…") { showAddBook = true }
                .font(TwelveTheme.Settings.rowPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var iCloudSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iCloud backup (optional)")
                .font(TwelveTheme.Settings.sectionHeader)
                .foregroundStyle(TwelveTheme.textSecondary)
            Toggle(isOn: $iCloudOn) {
                Text("Mirror data to iCloud Documents")
                    .font(TwelveTheme.Settings.rowPrimary)
            }
            .tint(TwelveTheme.primaryBlue)
            .onChange(of: iCloudOn) { _, v in
                ICloudDataMirror.ledgerEnabled = v
                if v, let data = try? JSONEncoder().encode(entries) {
                    ICloudDataMirror.mirrorLedgerJSON(data)
                }
            }
            Text(ICloudDataMirror.ledgerMirrorStatusLine())
                .font(TwelveTheme.Settings.caption)
                .foregroundStyle(TwelveTheme.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category shortcuts")
                .font(TwelveTheme.Settings.sectionHeader)
                .foregroundStyle(TwelveTheme.textSecondary)
            HStack(spacing: 8) {
                TextField("Add category…", text: $newCategoryShortcut)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button("Add") {
                    let t = newCategoryShortcut.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    guard !categories.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) else {
                        newCategoryShortcut = ""
                        return
                    }
                    categories.append(t)
                    LedgerCategoryStore.save(categories, for: bookStore.activeBookId)
                    newCategoryShortcut = ""
                    reloadLocalState()
                }
                .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
            }
            ForEach(categories, id: \.self) { c in
                HStack {
                    Text(c).font(TwelveTheme.Settings.rowPrimary)
                    Spacer()
                    Button("Remove", role: .destructive) {
                        categories.removeAll { $0 == c }
                        LedgerCategoryStore.save(categories, for: bookStore.activeBookId)
                    }
                    .font(TwelveTheme.Settings.rowPrimary)
                }
            }
            Text("Add your own labels or remove shortcuts; past transactions are unchanged.")
                .font(TwelveTheme.Settings.finePrint)
                .foregroundStyle(TwelveTheme.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var budgetsSection: some View {
        let y = monthNow.y
        let m = monthNow.m
        let applied = LedgerBudgetStore.budgets(for: bookStore.activeBookId, year: y, month: m)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Monthly budgets (expenses)")
                .font(TwelveTheme.Settings.sectionHeader)
                .foregroundStyle(TwelveTheme.textSecondary)
            Text("Caps follow the month you’re viewing on the main screen; “Every month” rolls with the calendar.")
                .font(TwelveTheme.Settings.finePrint)
                .foregroundStyle(TwelveTheme.textTertiary)
            ForEach(applied) { b in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.category)
                            .font(TwelveTheme.Settings.rowPrimary)
                        Text(b.repeatsEveryMonth ? "Every month" : "This month only")
                            .font(TwelveTheme.Settings.finePrint)
                            .foregroundStyle(TwelveTheme.textTertiary)
                        let spent = LedgerBudgetStore.spent(for: b.category, bookId: bookStore.activeBookId, year: y, month: m, entries: entries)
                        Text("\(currency.format(spent)) / \(currency.format(b.capAmount))")
                            .font(TwelveTheme.Settings.caption)
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    Spacer()
                    Button("Remove", role: .destructive) {
                        var all = LedgerBudgetStore.load()
                        all.removeAll { $0.id == b.id }
                        LedgerBudgetStore.save(all)
                        reloadLocalState()
                    }
                    .font(TwelveTheme.Settings.rowPrimary)
                }
            }
            Toggle(isOn: $budgetRepeatsMonthly) {
                Text("New budget repeats every month")
                    .font(TwelveTheme.Settings.rowPrimary)
            }
            .tint(TwelveTheme.primaryBlue)
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
                    if budgetRepeatsMonthly {
                        all.removeAll {
                            $0.bookId == bookStore.activeBookId && $0.repeatsEveryMonth
                                && $0.category.caseInsensitiveCompare(cat) == .orderedSame
                        }
                    }
                    all.append(
                        LedgerBudget(
                            bookId: bookStore.activeBookId,
                            year: y,
                            month: m,
                            category: cat,
                            capAmount: cap,
                            repeatsEveryMonth: budgetRepeatsMonthly
                        )
                    )
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
                .font(TwelveTheme.Settings.sectionHeader)
                .foregroundStyle(TwelveTheme.textSecondary)
            ForEach(recurring.filter { $0.bookId == bookStore.activeBookId }) { t in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.category)
                            .font(TwelveTheme.Settings.rowPrimary)
                        Text("\(t.kind.title) · day \(t.dayOfMonth) · \(currency.format(t.amount))")
                            .font(TwelveTheme.Settings.caption)
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
            HStack(spacing: 8) {
                TextField("Amount", text: $recAmount)
                    .keyboardType(.decimalPad)
                    .frame(width: 72)
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    recurringKindPill(.expense)
                    recurringKindPill(.income)
                }
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
                .font(TwelveTheme.Settings.sectionHeader)
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
                    .font(TwelveTheme.Settings.rowPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func recurringKindPill(_ k: LedgerTransactionKind) -> some View {
        let on = recKind == k
        return Button {
            recKind = k
        } label: {
            Text(k.title)
                .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                .foregroundStyle(on ? Color.white : TwelveTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        on
                            ? LinearGradient(
                                colors: [TwelveTheme.primaryBlue, TwelveTheme.primaryBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [TwelveTheme.secondarySurface, TwelveTheme.secondarySurface], startPoint: .top, endPoint: .bottom)
                    )
                )
                .overlay(Capsule().stroke(on ? Color.clear : TwelveTheme.strokeSoft, lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private func reloadLocalState() {
        categories = LedgerCategoryStore.load(for: bookStore.activeBookId)
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
