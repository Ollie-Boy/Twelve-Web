import SwiftUI

struct DiaryMonthSection: Identifiable {
    let monthStart: Date
    let entries: [DiaryEntry]
    var id: Date { monthStart }
}

struct ContentView: View {
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var selectedEntryForRead: DiaryEntry?
    @State private var selectedEntryForEdit: DiaryEntry?
    @State private var isComposerPresented: Bool = false

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
            if entries.isEmpty {
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
                ForEach(monthSections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.monthStart.formatted(.dateTime.year().month(.wide)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(BreezyTheme.textPrimary)
                            .padding(.leading, 2)

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
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var monthSections: [DiaryMonthSection] {
        let grouped = Dictionary(grouping: entries) { entry in
            let comps = Calendar.current.dateComponents([.year, .month], from: entry.selectedDate)
            return Calendar.current.date(from: comps) ?? entry.selectedDate
        }
        return grouped.keys.sorted(by: >).map { monthStart in
            let monthEntries = (grouped[monthStart] ?? []).sorted { $0.selectedDate > $1.selectedDate }
            return DiaryMonthSection(monthStart: monthStart, entries: monthEntries)
        }
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
}
