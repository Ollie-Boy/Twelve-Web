import SwiftUI

struct DiaryYearSection: Identifiable {
    let year: Int
    let entries: [DiaryEntry]
    var id: Int { year }
}

struct DiaryDaySection: Identifiable {
    let day: Date
    let entries: [DiaryEntry]
    var id: Date { day }
}

struct ContentView: View {
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var selectedEntryForRead: DiaryEntry?
    @State private var selectedEntryForEdit: DiaryEntry?
    @State private var isComposerPresented: Bool = false
    @State private var selectedYear: Int?
    @State private var selectedDayInYear: Date?

    private let storage = DiaryStorage()

    var body: some View {
        ZStack {
            BreezyTheme.background.ignoresSafeArea()
            WindyBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    headerBar
                    diaryListSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            entries = storage.loadEntries()
            sortEntries()
            if selectedYear == nil {
                selectedYear = yearSections.first?.year
            }
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
                    selectedYear = Calendar.current.component(.year, from: newEntry.selectedDate)
                }
            )
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
    }

    private var selectedEntryBinding: Binding<DiaryEntry?> {
        Binding(
            get: { selectedEntryForRead },
            set: { selectedEntryForRead = $0 }
        )
    }

    private var headerBar: some View {
        Text("Twelve")
            .font(.system(size: 36, weight: .bold))
            .foregroundStyle(BreezyTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var diaryListSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if yearSections.isEmpty {
                Text("No diary yet. Tap + to start writing.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BreezyTheme.hairline, lineWidth: 1)
                    )
            } else {
                yearMainPage
                if let selectedYear {
                    dayListForSelectedDate(in: selectedYear)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var yearMainPage: some View {
        TabView(selection: Binding(
            get: { selectedYear ?? yearSections.first?.year ?? 0 },
            set: { newYear in
                selectedYear = newYear
                selectedDayInYear = nil
            }
        )) {
            ForEach(yearSections) { section in
                VStack(alignment: .leading, spacing: 14) {
                    Text("\(section.year)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(BreezyTheme.textPrimary)
                    Text("\(section.entries.count) entries")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BreezyTheme.textSecondary)

                    YearCalendarGrid(
                        year: section.year,
                        entries: section.entries,
                        selectedDay: Binding(
                            get: { selectedDayInYear },
                            set: { selectedDayInYear = $0 }
                        )
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(BreezyTheme.hairline, lineWidth: 1)
                )
                .padding(.horizontal, 4)
                .tag(section.year)
            }
        }
        .frame(height: 560)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    @ViewBuilder
    private func dayListForSelectedDate(in year: Int) -> some View {
        if let selectedDayInYear {
            let dayEntries = entriesForDay(selectedDayInYear)
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedDayInYear.formatted(.dateTime.year().month(.wide).day()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(BreezyTheme.textPrimary)
                if dayEntries.isEmpty {
                    Text("No entries for selected date.")
                        .font(.system(size: 14))
                        .foregroundStyle(BreezyTheme.textSecondary)
                } else {
                    ForEach(dayEntries) { entry in
                        EntryCardView(
                            entry: entry,
                            onOpen: { selectedEntryForRead = entry },
                            onEdit: { selectedEntryForEdit = entry },
                            onDelete: { pendingDeletionEntry = entry }
                        )
                    }
                }
            }
        } else {
            let yearEntries = entries.filter { Calendar.current.component(.year, from: $0.selectedDate) == year }
            let grouped = Dictionary(grouping: yearEntries) { Calendar.current.startOfDay(for: $0.selectedDate) }
            let days = grouped.keys.sorted(by: >)
            VStack(alignment: .leading, spacing: 12) {
                Text("All entries in \(year)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(BreezyTheme.textPrimary)
                ForEach(days, id: \.self) { day in
                    if let dayEntries = grouped[day] {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(day.formatted(.dateTime.month(.wide).day()))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(BreezyTheme.textPrimary)
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

    private var addButton: some View {
        Button {
            isComposerPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [BreezyTheme.primaryBlue, BreezyTheme.primaryBlueDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: BreezyTheme.primaryBlue.opacity(0.3), radius: 12, y: 7)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    private var yearSections: [DiaryYearSection] {
        let grouped = Dictionary(grouping: entries) { Calendar.current.component(.year, from: $0.selectedDate) }
        return grouped.keys.sorted(by: <).map { year in
            let yearEntries = (grouped[year] ?? []).sorted { $0.selectedDate > $1.selectedDate }
            return DiaryYearSection(year: year, entries: yearEntries)
        }
    }

    private func entriesForDay(_ day: Date) -> [DiaryEntry] {
        let target = Calendar.current.startOfDay(for: day)
        return entries
            .filter { Calendar.current.startOfDay(for: $0.selectedDate) == target }
            .sorted { $0.selectedDate > $1.selectedDate }
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
        if let selectedYear, !entries.contains(where: { Calendar.current.component(.year, from: $0.selectedDate) == selectedYear }) {
            self.selectedYear = yearSections.first?.year
            selectedDayInYear = nil
        }
    }

    private func sortEntries() {
        entries.sort { $0.selectedDate > $1.selectedDate }
    }
}

private struct YearCalendarGrid: View {
    let year: Int
    let entries: [DiaryEntry]
    @Binding var selectedDay: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(1...12, id: \.self) { month in
                VStack(alignment: .leading, spacing: 6) {
                    Text(monthTitle(month))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textSecondary)
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(daysInMonth(month), id: \.self) { day in
                            if let dayDate = date(year: year, month: month, day: day) {
                                let hasEntry = entries.contains { Calendar.current.isDate($0.selectedDate, inSameDayAs: dayDate) }
                                Button {
                                    selectedDay = dayDate
                                } label: {
                                    Text("\(day)")
                                        .font(.system(size: 11, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(
                                            hasEntry ? BreezyTheme.softBlue : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(hasEntry ? BreezyTheme.primaryBlue.opacity(0.45) : BreezyTheme.hairline, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    private func daysInMonth(_ month: Int) -> [Int] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = Calendar.current.date(from: components),
              let range = Calendar.current.range(of: .day, in: .month, for: date)
        else { return [] }
        return Array(range)
    }

    private func monthTitle(_ month: Int) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.wide))
    }
}

#Preview {
    ContentView()
}
