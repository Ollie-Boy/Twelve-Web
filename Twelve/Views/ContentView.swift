import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var selectedEntryForRead: DiaryEntry?
    @State private var selectedEntryForEdit: DiaryEntry?
    @State private var isComposerPresented: Bool = false
    @State private var showDayPickerSheet: Bool = false
    @State private var showAppearanceSheet: Bool = false
    @State private var showDiarySettings: Bool = false
    @State private var showSearch: Bool = false

    private let storage = DiaryStorage()

    var body: some View {
        ZStack {
            TwelveTheme.background.ignoresSafeArea()
            WindyBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    headerBar
                    onThisDayCard
                    diaryListSection
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
        .alert(item: $pendingDeletionEntry) { entry in
            Alert(
                title: Text("Delete this entry?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) { deleteEntry(entry) },
                secondaryButton: .cancel()
            )
        }
        .sheet(item: selectedEntryBinding) { entry in
            DiaryReaderPagerSheet(
                entries: entries,
                initialEntryID: entry.id,
                onEdit: { selectedEntryForEdit = $0 },
                onDelete: {
                    let id = $0.id
                    selectedEntryForRead = nil
                    if let liveEntry = entries.first(where: { $0.id == id }) {
                        deleteEntry(liveEntry)
                    } else {
                        deleteEntry($0)
                    }
                }
            )
        }
        .sheet(item: $selectedEntryForEdit) { entry in
            DiaryComposerSheet(
                isPresented: Binding(
                    get: { selectedEntryForEdit != nil },
                    set: { if !$0 { selectedEntryForEdit = nil } }
                ),
                mode: .edit(entry),
                onSave: { updated in
                    if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                        entries[index] = updated
                        sortEntries()
                        storage.saveEntries(entries)
                    }
                }
            )
        }
        .sheet(isPresented: $isComposerPresented) {
            DiaryComposerSheet(
                isPresented: $isComposerPresented,
                mode: .create,
                onSave: { newEntry in
                    entries.insert(newEntry, at: 0)
                    sortEntries()
                    storage.saveEntries(entries)
                }
            )
        }
        .sheet(isPresented: $showDayPickerSheet) {
            DiaryDayPickerSheet(entries: entries) { entry in
                selectedEntryForRead = entry
            }
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearancePickerSheet()
                .environmentObject(appearance)
        }
        .sheet(isPresented: $showDiarySettings) {
            DiarySettingsSheet(entries: entries) {
                entries = storage.loadEntries()
                sortEntries()
            }
        }
        .sheet(isPresented: $showSearch) {
            DiarySearchSheet(entries: entries) { e in
                selectedEntryForRead = e
            }
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
    }

    /// Full-width blur only in the status bar vertical band (matches system status bar height).
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

    private var selectedEntryBinding: Binding<DiaryEntry?> {
        Binding(
            get: { selectedEntryForRead },
            set: { selectedEntryForRead = $0 }
        )
    }

    private var todayWeather: WeatherOption {
        WeatherOption.suggestedForRecognizedAddress("", date: Date())
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
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(TwelveTheme.appFont(size: 22, weight: .medium))
                        .foregroundStyle(TwelveTheme.primaryBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search diary")

                Button {
                    showDayPickerSheet = true
                } label: {
                    SketchCalendarIcon(size: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to date")

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
                    showDiarySettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(TwelveTheme.appFont(size: 22, weight: .medium))
                        .foregroundStyle(TwelveTheme.primaryBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Diary settings")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var onThisDayPastEntries: [DiaryEntry] {
        DiaryOnThisDay.pastYearEntries(matching: Date(), in: entries)
    }

    @ViewBuilder
    private var onThisDayCard: some View {
        let past = onThisDayPastEntries
        if !past.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("On this day")
                    .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textSecondary)
                ForEach(past.prefix(3)) { e in
                    Button {
                        selectedEntryForRead = e
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text(e.selectedDate.formatted(.dateTime.year()))
                                .font(TwelveTheme.appFont(size: 12, weight: .bold))
                                .foregroundStyle(TwelveTheme.primaryBlue)
                                .frame(width: 44, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title.isEmpty ? "Untitled" : e.title)
                                    .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                                    .foregroundStyle(TwelveTheme.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(TwelveTheme.appFont(size: 12, weight: .semibold))
                                .foregroundStyle(TwelveTheme.textTertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
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

    private var diaryListSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if entries.isEmpty {
                DiaryEmptyStateView {
                    isComposerPresented = true
                }
            } else {
                entryListByMonthAndDay
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var entryListByMonthAndDay: some View {
        let groupedByMonth = Dictionary(grouping: entries) { entry in
            let components = Calendar.current.dateComponents([.year, .month], from: entry.selectedDate)
            return Calendar.current.date(from: components) ?? entry.selectedDate
        }
        let sortedMonths = groupedByMonth.keys.sorted(by: >)

        return VStack(alignment: .leading, spacing: 16) {
            ForEach(sortedMonths, id: \.self) { month in
                if let monthEntries = groupedByMonth[month] {
                    let groupedByDay = Dictionary(grouping: monthEntries) { Calendar.current.startOfDay(for: $0.selectedDate) }
                    let sortedDays = groupedByDay.keys.sorted(by: >)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(month.formatted(.dateTime.year().month(.wide)))
                            .font(TwelveTheme.appFont(size: 22, weight: .bold))
                            .foregroundStyle(TwelveTheme.textPrimary)

                        ForEach(sortedDays, id: \.self) { day in
                            if let dayEntries = groupedByDay[day] {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(day.formatted(.dateTime.month(.wide).day()))
                                        .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                                        .foregroundStyle(TwelveTheme.textPrimary)
                                        .padding(.leading, 2)
                                    ForEach(dayEntries.sorted { $0.selectedDate > $1.selectedDate }) { entry in
                                        EntryCardView(
                                            entry: entry,
                                            onOpen: { selectedEntryForRead = entry },
                                            onEdit: { selectedEntryForEdit = entry },
                                            onDelete: { pendingDeletionEntry = entry }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            isComposerPresented = true
        } label: {
            ZStack {
                Circle()
                    .fill(TwelveTheme.softBlue)
                SketchPlusIcon(size: 30, color: TwelveTheme.primaryBlue, lineWidth: 3.4)
            }
            .frame(width: 58, height: 58)
            .overlay(
                Circle()
                    .stroke(TwelveTheme.primaryBlue.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: TwelveTheme.primaryBlue.opacity(0.18), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private func deleteEntry(_ entry: DiaryEntry) {
        entries.removeAll { $0.id == entry.id }
        storage.saveEntries(entries)
        if selectedEntryForRead?.id == entry.id {
            selectedEntryForRead = nil
        }
        if selectedEntryForEdit?.id == entry.id {
            selectedEntryForEdit = nil
        }
    }

    private func sortEntries() {
        entries.sort { $0.selectedDate > $1.selectedDate }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppearanceStore())
}
