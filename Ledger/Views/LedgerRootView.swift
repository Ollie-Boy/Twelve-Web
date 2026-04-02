import SwiftUI

struct LedgerRootView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @State private var entries: [LedgerEntry] = []
    @State private var pendingDeletion: LedgerEntry?
    @State private var showAddSheet = false
    @State private var showAppearanceSheet = false

    private let storage = LedgerStorage()

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }

    private var monthSummary: (income: Decimal, expense: Decimal) {
        let cal = Calendar.current
        let now = Date()
        var income: Decimal = 0
        var expense: Decimal = 0
        for e in entries {
            guard cal.isDate(e.date, equalTo: now, toGranularity: .month) else { continue }
            if e.isExpense {
                expense += e.amount
            } else {
                income += e.amount
            }
        }
        return (income, expense)
    }

    var body: some View {
        ZStack {
            TwelveTheme.background.ignoresSafeArea()
            WindyBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    headerBar
                    summaryPanel
                    transactionSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
            }

            statusBarBlurStrip
        }
        .onAppear {
            entries = storage.loadEntries()
            sortEntries()
        }
        .sheet(isPresented: $showAddSheet) {
            LedgerAddTransactionSheet(isPresented: $showAddSheet) { new in
                entries.insert(new, at: 0)
                sortEntries()
                storage.saveEntries(entries)
            }
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearancePickerSheet()
                .environmentObject(appearance)
        }
        .alert(item: $pendingDeletion) { entry in
            Alert(
                title: Text("Delete this entry?"),
                message: Text("This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) { delete(entry) },
                secondaryButton: .cancel()
            )
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
    }

    private var statusBarBlurStrip: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: proxy.safeAreaInsets.top)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .top)
    }

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Ledger")
                .font(TwelveTheme.handwrittenFont(size: 40))
                .foregroundStyle(TwelveTheme.textPrimary)
            Spacer(minLength: 8)
            Button {
                showAppearanceSheet = true
            } label: {
                SketchPaletteIcon(size: 28)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Look and feel")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryPanel: some View {
        let s = monthSummary
        let net = s.income - s.expense
        return VStack(alignment: .leading, spacing: 12) {
            Text(Date().formatted(.dateTime.month(.wide).year()))
                .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                .foregroundStyle(TwelveTheme.textPrimary)

            HStack(spacing: 16) {
                summaryChip(title: "In", value: s.income, color: TwelveTheme.primaryBlue)
                summaryChip(title: "Out", value: s.expense, color: TwelveTheme.primaryBlueDark)
            }
            Text("Net \(formatMoney(net))")
                .font(TwelveTheme.appFont(size: 15, weight: .medium))
                .foregroundStyle(net >= 0 ? TwelveTheme.textPrimary : TwelveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cartoonPanelChrome()
    }

    private func summaryChip(title: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(TwelveTheme.appFont(size: 12, weight: .medium))
                .foregroundStyle(TwelveTheme.textTertiary)
            Text(formatMoney(value))
                .font(TwelveTheme.appFont(size: 18, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if entries.isEmpty {
                Text("No transactions yet. Tap + to add one.")
                    .font(TwelveTheme.appFont(size: 16))
                    .foregroundStyle(TwelveTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(TwelveTheme.hairline, lineWidth: 1)
                    )
            } else {
                let grouped = Dictionary(grouping: entries) { e in
                    let c = Calendar.current.dateComponents([.year, .month], from: e.date)
                    return Calendar.current.date(from: c) ?? e.date
                }
                let months = grouped.keys.sorted(by: >)
                ForEach(months, id: \.self) { month in
                    if let list = grouped[month] {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(month.formatted(.dateTime.year().month(.wide)))
                                .font(TwelveTheme.appFont(size: 22, weight: .bold))
                                .foregroundStyle(TwelveTheme.textPrimary)
                            ForEach(list.sorted { $0.date > $1.date }) { entry in
                                transactionRow(entry)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func transactionRow(_ entry: LedgerEntry) -> some View {
        let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category)
                    .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textPrimary)
                if !note.isEmpty {
                    Text(note)
                        .font(TwelveTheme.appFont(size: 13))
                        .foregroundStyle(TwelveTheme.textSecondary)
                        .lineLimit(2)
                }
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(TwelveTheme.appFont(size: 12))
                    .foregroundStyle(TwelveTheme.textTertiary)
            }
            Spacer(minLength: 8)
            Text(entry.isExpense ? "−\(formatMoney(entry.amount))" : "+\(formatMoney(entry.amount))")
                .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                .foregroundStyle(entry.isExpense ? TwelveTheme.primaryBlueDark : TwelveTheme.primaryBlue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TwelveTheme.hairline, lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                pendingDeletion = entry
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            ZStack {
                Circle().fill(
                    LinearGradient(
                        colors: [TwelveTheme.primaryBlue, TwelveTheme.primaryBlueDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                SketchPlusIcon(size: 30, color: .white, lineWidth: 3.4)
            }
            .frame(width: 58, height: 58)
            .shadow(color: TwelveTheme.primaryBlue.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func formatMoney(_ value: Decimal) -> String {
        currencyFormatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func delete(_ entry: LedgerEntry) {
        entries.removeAll { $0.id == entry.id }
        storage.saveEntries(entries)
    }

    private func sortEntries() {
        entries.sort { $0.date > $1.date }
    }
}

#Preview {
    LedgerRootView()
        .environmentObject(AppearanceStore(storageKey: "ledgerAppearancePreference", legacyStorageKey: nil))
}
