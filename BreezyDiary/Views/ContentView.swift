import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var selectedEntryForRead: DiaryEntry?
    @State private var selectedEntryForEdit: DiaryEntry?
    @State private var isComposerPresented: Bool = false
    @State private var showAppearanceSheet: Bool = false

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
        HStack(alignment: .center, spacing: 12) {
            Text("Twelve")
                .font(BreezyTheme.handwrittenFont(size: 40))
                .foregroundStyle(BreezyTheme.textPrimary)
            Spacer(minLength: 8)
            Button {
                showAppearanceSheet = true
            } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .font(BreezyTheme.appFont(size: 20, weight: .medium))
                    .foregroundStyle(BreezyTheme.primaryBlue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Appearance")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showAppearanceSheet) {
            AppearancePickerSheet(
                selection: Binding(
                    get: { appearance.preference },
                    set: { appearance.setPreference($0) }
                )
            )
        }
    }

    private var diaryListSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if entries.isEmpty {
                Text("No diary yet. Tap + to start writing.")
                    .font(BreezyTheme.appFont(size: 16))
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BreezyTheme.hairline, lineWidth: 1)
                    )
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
                            .font(BreezyTheme.appFont(size: 22, weight: .bold))
                            .foregroundStyle(BreezyTheme.textPrimary)

                        ForEach(sortedDays, id: \.self) { day in
                            if let dayEntries = groupedByDay[day] {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(day.formatted(.dateTime.month(.wide).day()))
                                        .font(BreezyTheme.appFont(size: 16, weight: .semibold))
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
        }
    }

    private var addButton: some View {
        Button {
            isComposerPresented = true
        } label: {
            Image(systemName: "plus")
                .font(BreezyTheme.appFont(size: 18, weight: .bold))
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

private struct AppearancePickerSheet: View {
    @Binding var selection: AppearancePreference
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppearancePreference.allCases) { option in
                    Button {
                        selection = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.title)
                                .font(BreezyTheme.appFont(size: 17))
                                .foregroundStyle(BreezyTheme.textPrimary)
                            Spacer()
                            if selection == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(BreezyTheme.appFont(size: 18, weight: .semibold))
                                    .foregroundStyle(BreezyTheme.primaryBlue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(BreezyTheme.background.ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(BreezyTheme.appFont(size: 17))
                }
            }
        }
        .presentationDetents([.medium])
        .font(BreezyTheme.appFont(size: 17))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppearanceStore())
}
