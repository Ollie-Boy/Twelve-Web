import SwiftUI

struct DiaryYearSection: Identifiable {
    let year: Int
    let entries: [DiaryEntry]
    var id: Int { year }
}

struct DiaryMonthSection: Identifiable {
    let year: Int
    let month: Int
    let entries: [DiaryEntry]
    var id: String { "\(year)-\(month)" }
}

struct ContentView: View {
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var selectedEntryForRead: DiaryEntry?
    @State private var selectedEntryForEdit: DiaryEntry?
    @State private var isComposerPresented: Bool = false
    @State private var selectedYear: Int?

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
            selectedYear = yearSections.first?.year
        }
        .alert(item: $pendingDeletionEntry) { entry in
            Alert(
                title: Text("Delete this entry?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) { deleteEntry(entry) },
                secondaryButton: .cancel()
            )
        }
        .sheet(item: $selectedEntryForRead) { entry in
            DiaryReaderSheet(
                entry: entry,
                onEdit: {
                    selectedEntryForRead = nil
                    selectedEntryForEdit = entry
                },
                onDelete: {
                    let entryID = entry.id
                    selectedEntryForRead = nil
                    if let liveEntry = entries.first(where: { $0.id == entryID }) {
                        deleteEntry(liveEntry)
                    } else {
                        deleteEntry(entry)
                    }
                }
            )
        }
        .sheet(item: $selectedEntryForEdit) { entry in
            DiaryComposerSheet(
                isPresented: Binding(
                    get: { selectedEntryForEdit != nil },
                    set: { presented in
                        if !presented {
                            selectedEntryForEdit = nil
                        }
                    }
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
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Diary")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(BreezyTheme.textPrimary)
            Text("Browse entries by year, then by month and day.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(BreezyTheme.textSecondary)
        }
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
                yearCarousel
                if let selectedYear {
                    yearDetailSection(year: selectedYear)
                } else if let firstYear = yearSections.first?.year {
                    yearDetailSection(year: firstYear)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var yearCarousel: some View {
        TabView(selection: Binding(
            get: { selectedYear ?? yearSections.first?.year ?? 0 },
            set: { selectedYear = $0 }
        )) {
            ForEach(yearSections) { section in
                Button {
                    selectedYear = section.year
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(section.year)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(BreezyTheme.textPrimary)
                        Text("\(section.entries.count) entries")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(BreezyTheme.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
                .tag(section.year)
            }
        }
        .frame(height: 146)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    @ViewBuilder
    private func yearDetailSection(year: Int) -> some View {
        let monthSections = monthSections(for: year)
        VStack(alignment: .leading, spacing: 14) {
            Text("\(year)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(BreezyTheme.textPrimary)
                .padding(.leading, 2)

            ForEach(monthSections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(monthTitle(year: section.year, month: section.month))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textPrimary)
                        .padding(.leading, 4)

                    ForEach(section.entries) { entry in
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
        return grouped.keys.sorted(by: >).map { year in
            let yearEntries = (grouped[year] ?? []).sorted { $0.selectedDate > $1.selectedDate }
            return DiaryYearSection(year: year, entries: yearEntries)
        }
    }

    private func monthSections(for year: Int) -> [DiaryMonthSection] {
        let calendar = Calendar.current
        let yearEntries = entries.filter { calendar.component(.year, from: $0.selectedDate) == year }
        let grouped = Dictionary(grouping: yearEntries) { calendar.component(.month, from: $0.selectedDate) }
        return grouped.keys.sorted(by: >).map { month in
            let monthEntries = (grouped[month] ?? []).sorted { $0.selectedDate > $1.selectedDate }
            return DiaryMonthSection(year: year, month: month, entries: monthEntries)
        }
    }

    private func monthTitle(year: Int, month: Int) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.year().month(.wide))
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
        selectedYear = yearSections.first?.year
    }

    private func sortEntries() {
        entries.sort { $0.selectedDate > $1.selectedDate }
    }
}

#Preview {
    ContentView()
}
