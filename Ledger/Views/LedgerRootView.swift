import SwiftUI

struct LedgerRootView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @EnvironmentObject private var currency: LedgerCurrencyStore
    @StateObject private var bookStore = LedgerBookStore()

    @State private var entries: [LedgerEntry] = []
    @State private var pendingDeletion: LedgerEntry?
    @State private var showAddSheet = false
    @State private var entryToEdit: LedgerEntry?
    @State private var showAppearanceSheet = false
    @State private var showDayPickerSheet = false
    @State private var showCurrencySheet = false
    @State private var showSettingsSheet = false
    @State private var showMonthReviewSheet = false
    @State private var summaryMonthSelection: Date = LedgerRootView.startOfMonth(for: Date())

    private let storage = LedgerStorage()

    private var bookEntries: [LedgerEntry] {
        entries.filter { $0.bookId == bookStore.activeBookId }
    }

    private var summaryPageMonths: [Date] {
        var set = Set<Date>()
        set.insert(Self.startOfMonth(for: Date()))
        for e in bookEntries {
            set.insert(Self.startOfMonth(for: e.date))
        }
        return set.sorted()
    }

    private var todayWeather: WeatherOption {
        WeatherOption.suggestedForRecognizedAddress("", date: Date())
    }

    private func transactionCount(for monthStart: Date) -> Int {
        let cal = Calendar.current
        return bookEntries.filter { cal.isDate($0.date, equalTo: monthStart, toGranularity: .month) }.count
    }

    private func summaryMonthSubtitle(for monthStart: Date) -> String {
        let n = transactionCount(for: monthStart)
        let noun = n == 1 ? "entry" : "entries"
        return "\(n) \(noun) · swipe for other months"
    }

    private func monthSummary(for monthStart: Date) -> (income: Decimal, expense: Decimal) {
        let cal = Calendar.current
        var income: Decimal = 0
        var expense: Decimal = 0
        for e in bookEntries {
            guard cal.isDate(e.date, equalTo: monthStart, toGranularity: .month) else { continue }
            switch e.kind {
            case .expense:
                expense += e.netAmount
            case .income:
                income += e.netAmount
            }
        }
        return (
            LedgerDecimalFormatting.round(income),
            LedgerDecimalFormatting.round(expense)
        )
    }

    private func budgetsStrip(for monthStart: Date) -> some View {
        let cal = Calendar.current
        let y = cal.component(.year, from: monthStart)
        let m = cal.component(.month, from: monthStart)
        let list = LedgerBudgetStore.budgets(for: bookStore.activeBookId, year: y, month: m)
        guard !list.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("Budgets")
                    .font(TwelveTheme.appFont(size: 12, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textTertiary)
                ForEach(list) { b in
                    let spent = LedgerBudgetStore.spent(for: b.category, bookId: bookStore.activeBookId, year: y, month: m, entries: bookEntries)
                    let capD = (b.capAmount as NSDecimalNumber).doubleValue
                    let spD = (spent as NSDecimalNumber).doubleValue
                    let frac = capD > 0 ? min(spD / capD, 1.5) : 0
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(b.category)
                                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            Spacer()
                            Text("\(currency.format(spent)) / \(currency.format(b.capAmount))")
                                .font(TwelveTheme.appFont(size: 12))
                                .foregroundStyle(TwelveTheme.textSecondary)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(TwelveTheme.secondarySurface)
                                Capsule()
                                    .fill(frac > 1 ? Color.orange.opacity(0.7) : TwelveTheme.softBlue)
                                    .frame(width: g.size.width * CGFloat(min(frac, 1)))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding(.top, 4)
        )
    }

    var body: some View {
        ZStack {
            TwelveTheme.background.ignoresSafeArea()
            WindyBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    headerBar
                    summaryPanel
                    chartSection
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
            syncSummaryMonthSelection()
        }
        .onChange(of: entries) { _, _ in
            syncSummaryMonthSelection()
        }
        .onChange(of: bookStore.activeBookId) { _, _ in
            syncSummaryMonthSelection()
        }
        .sheet(isPresented: $showAddSheet) {
            LedgerAddTransactionSheet(
                isPresented: $showAddSheet,
                mode: .create,
                bookId: bookStore.activeBookId,
                categorySuggestions: LedgerCategoryStore.load(for: bookStore.activeBookId),
                onSave: { new in
                    entries.insert(new, at: 0)
                    sortEntries()
                    storage.saveEntries(entries)
                }
            )
        }
        .sheet(item: $entryToEdit) { entry in
            LedgerAddTransactionSheet(
                isPresented: Binding(
                    get: { entryToEdit != nil },
                    set: { if !$0 { entryToEdit = nil } }
                ),
                mode: .edit(entry),
                bookId: bookStore.activeBookId,
                categorySuggestions: LedgerCategoryStore.load(for: bookStore.activeBookId),
                onSave: { updated in
                    if let i = entries.firstIndex(where: { $0.id == updated.id }) {
                        entries[i] = updated
                        sortEntries()
                        storage.saveEntries(entries)
                    }
                    entryToEdit = nil
                }
            )
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearancePickerSheet()
                .environmentObject(appearance)
        }
        .sheet(isPresented: $showDayPickerSheet) {
            LedgerDayPickerSheet(entries: bookEntries, formatMoney: { currency.format($0) })
        }
        .sheet(isPresented: $showCurrencySheet) {
            LedgerCurrencyPickerSheet(currency: currency)
        }
        .sheet(isPresented: $showMonthReviewSheet) {
            LedgerMonthReviewSheet(
                monthStart: summaryMonthSelection,
                bookId: bookStore.activeBookId,
                entries: bookEntries,
                formatMoney: { currency.format($0) }
            )
        }
        .sheet(isPresented: $showSettingsSheet) {
            LedgerSettingsSheet(
                bookStore: bookStore,
                entries: $entries,
                currency: currency,
                storage: storage,
                onDismissReload: {
                    entries = storage.loadEntries()
                    sortEntries()
                }
            )
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

    private func syncSummaryMonthSelection() {
        let pages = summaryPageMonths
        guard !pages.isEmpty else {
            summaryMonthSelection = Self.startOfMonth(for: Date())
            return
        }
        if !pages.contains(where: { Calendar.current.isDate($0, equalTo: summaryMonthSelection, toGranularity: .month) }) {
            let current = Self.startOfMonth(for: Date())
            summaryMonthSelection = pages.contains(where: { Calendar.current.isDate($0, equalTo: current, toGranularity: .month) })
                ? current
                : (pages.last ?? current)
        }
    }

    private static func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: c) ?? date
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
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: todayWeather.symbolName)
                    .font(TwelveTheme.appFont(size: 26, weight: .semibold))
                    .foregroundStyle(TwelveTheme.primaryBlue)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 2) {
                    Text(todayWeather.title)
                        .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                        .lineLimit(1)
                    Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(TwelveTheme.appFont(size: 13, weight: .medium))
                        .foregroundStyle(TwelveTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(todayWeather.title), \(Date().formatted(date: .complete, time: .omitted))"
            )
            Spacer(minLength: 8)
            HStack(spacing: 10) {
                Button {
                    showDayPickerSheet = true
                } label: {
                    SketchCalendarIcon(size: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to day")

                Button {
                    showCurrencySheet = true
                } label: {
                    Text(currency.currencyCode)
                        .font(TwelveTheme.appFont(size: 18, weight: .semibold))
                        .foregroundStyle(TwelveTheme.primaryBlue)
                        .tracking(0.6)
                        .frame(minWidth: 48, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Currency")

                Button {
                    showAppearanceSheet = true
                } label: {
                    SketchPaletteIcon(size: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Look and feel")

                Button {
                    showSettingsSheet = true
                } label: {
                    SketchGearIcon(size: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ledger settings")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryPanel: some View {
        let pages = summaryPageMonths
        return VStack(spacing: 10) {
            TabView(selection: $summaryMonthSelection) {
                ForEach(pages, id: \.self) { anchor in
                    summaryPageContent(monthStart: anchor)
                        .padding(.horizontal, 4)
                        .tag(anchor)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
        }
        .cartoonPanelChrome()
    }

    private func summaryPageContent(monthStart: Date) -> some View {
        let s = monthSummary(for: monthStart)
        let net = s.income - s.expense
        let roundedNet = LedgerDecimalFormatting.round(net)
        let goal = LedgerSimpleGoalStore.savingsTarget(for: bookStore.activeBookId)
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthStart.formatted(.dateTime.month(.wide).year()))
                    .font(TwelveTheme.appFont(size: 22, weight: .bold))
                    .foregroundStyle(TwelveTheme.textPrimary)
                Text(summaryMonthSubtitle(for: monthStart))
                    .font(TwelveTheme.appFont(size: 13, weight: .medium))
                    .foregroundStyle(TwelveTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                summaryChip(title: "In", value: s.income, color: TwelveTheme.primaryBlue)
                summaryChip(title: "Out", value: s.expense, color: TwelveTheme.primaryBlueDark)
            }
            Text("Net \(currency.format(roundedNet))")
                .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                .foregroundStyle(net >= 0 ? TwelveTheme.textPrimary : TwelveTheme.textSecondary)

            if let g = goal {
                let met = roundedNet >= g
                HStack(spacing: 8) {
                    Text("Goal ≥ \(currency.format(g))")
                        .font(TwelveTheme.appFont(size: 12, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textSecondary)
                    Spacer(minLength: 4)
                    Text(met ? "On track" : "Below goal")
                        .font(TwelveTheme.appFont(size: 12, weight: .semibold))
                        .foregroundStyle(met ? TwelveTheme.primaryBlue : Color.orange.opacity(0.9))
                }
            }

            Button {
                showMonthReviewSheet = true
            } label: {
                Text("Month review")
                    .font(TwelveTheme.appFont(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.surfaceTintBlue))

            budgetsStrip(for: monthStart)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryChip(title: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textTertiary)
            Text(currency.format(value))
                .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var chartSection: some View {
        let pts = LedgerChartData.monthlyNetSeries(bookId: bookStore.activeBookId, entries: bookEntries)
        if !bookEntries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly net (drag sideways)")
                    .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textSecondary)
                LedgerMonthChartView(points: pts, formatMoney: { currency.format($0) })
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TwelveTheme.hairline, lineWidth: 1)
            )
        }
    }

    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if bookEntries.isEmpty {
                LedgerEmptyStateView {
                    showAddSheet = true
                }
            } else {
                let grouped = Dictionary(grouping: bookEntries) { e in
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
        let loc = entry.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return LedgerSwipeActionRow(
            onEdit: { entryToEdit = entry },
            onDelete: { pendingDeletion = entry }
        ) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(entry.category)
                            .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                            .foregroundStyle(TwelveTheme.textPrimary)
                        if entry.refundTotal > 0 {
                            Text("Refund")
                                .font(TwelveTheme.appFont(size: 10, weight: .bold))
                                .foregroundStyle(TwelveTheme.primaryBlueDark)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(TwelveTheme.softBlue.opacity(0.5), in: Capsule())
                        }
                    }
                    if !note.isEmpty {
                        Text(note)
                            .font(TwelveTheme.appFont(size: 13))
                            .foregroundStyle(TwelveTheme.textSecondary)
                            .lineLimit(2)
                    }
                    if !loc.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(TwelveTheme.appFont(size: 11))
                                .foregroundStyle(TwelveTheme.textTertiary)
                            Text(loc)
                                .font(TwelveTheme.appFont(size: 11))
                                .foregroundStyle(TwelveTheme.textTertiary)
                                .lineLimit(2)
                        }
                    }
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(TwelveTheme.appFont(size: 12))
                        .foregroundStyle(TwelveTheme.textTertiary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rowAmountLabel(entry))
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(rowAmountColor(entry))
                    if entry.refundTotal > 0, entry.amount > entry.netAmount {
                        Text("was \(currency.format(entry.amount))")
                            .font(TwelveTheme.appFont(size: 11))
                            .foregroundStyle(TwelveTheme.textTertiary)
                            .strikethrough(true, color: TwelveTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TwelveTheme.hairline, lineWidth: 1)
            )
        }
    }

    private func rowAmountLabel(_ entry: LedgerEntry) -> String {
        switch entry.kind {
        case .expense:
            return "−\(currency.format(entry.netAmount))"
        case .income:
            return "+\(currency.format(entry.netAmount))"
        }
    }

    private func rowAmountColor(_ entry: LedgerEntry) -> Color {
        switch entry.kind {
        case .expense:
            return TwelveTheme.primaryBlueDark
        case .income:
            return TwelveTheme.primaryBlue
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
        .environmentObject(LedgerCurrencyStore())
}
