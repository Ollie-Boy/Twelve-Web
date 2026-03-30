import SwiftUI

struct DiaryDaySection: Identifiable {
    let id = UUID()
    let day: Date
    let entries: [DiaryEntry]
}

struct ContentView: View {
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var isFeatureCardPresented: Bool = true
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
        .sheet(item: $selectedEntryForRead) { entry in
            DiaryReaderSheet(
                entry: entry,
                onEdit: { selectedEntryForEdit = entry },
                onDelete: { pendingDeletionEntry = entry }
            )
        }
        .sheet(item: $selectedEntryForEdit) { entry in
            DiaryComposerSheet(
                isPresented: bindingForEditSheet,
                mode: .edit(entry),
                onSave: { updated in
                    if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                        entries[index] = updated
                        sortEntries()
                        storage.saveEntries(entries)
                    }
                    selectedEntryForEdit = nil
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
        .overlay {
            if isFeatureCardPresented {
                TodayFeatureCardOverlay(
                    isPresented: $isFeatureCardPresented,
                    onStartWriting: { isComposerPresented = true }
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
                .zIndex(10)
            }
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Diary")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(BreezyTheme.textPrimary)
            Text("Browse entries by date, App Store style.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(BreezyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var diaryListSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if groupedSections.isEmpty {
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
                ForEach(groupedSections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(sectionTitle(section.day))
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

    private var groupedSections: [DiaryDaySection] {
        let grouped = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.selectedDate) }
        let sortedDays = grouped.keys.sorted(by: >)
        var sections: [DiaryDaySection] = []
        sections.reserveCapacity(sortedDays.count)
        for day in sortedDays {
            let dayEntries = (grouped[day] ?? []).sorted { $0.selectedDate > $1.selectedDate }
            sections.append(DiaryDaySection(day: day, entries: dayEntries))
        }
        return sections
    }

    private func sectionTitle(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.wide).day())
    }

    private func deleteEntry(_ entry: DiaryEntry) {
        entries.removeAll { $0.id == entry.id }
        storage.saveEntries(entries)
    }

    private func sortEntries() {
        entries.sort { $0.selectedDate > $1.selectedDate }
    }

    private var bindingForEditSheet: Binding<Bool> {
        Binding(
            get: { selectedEntryForEdit != nil },
            set: { isPresented in
                if !isPresented {
                    selectedEntryForEdit = nil
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
