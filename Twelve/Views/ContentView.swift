import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @State private var entries: [DiaryEntry] = []
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var selectedEntryForRead: DiaryEntry?
    @State private var selectedEntryForEdit: DiaryEntry?
    @State private var isComposerPresented: Bool = false

    private let storage = DiaryStorage()

    var body: some View {
        ZStack {
            TwelveTheme.background.ignoresSafeArea()
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

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Twelve")
                .font(TwelveTheme.handwrittenFont(size: 40))
                .foregroundStyle(TwelveTheme.textPrimary)
            Spacer(minLength: 8)
            Menu {
                ForEach(AppearancePreference.allCases) { option in
                    Button {
                        appearance.setPreference(option)
                    } label: {
                        HStack {
                            Text(option.title)
                                .font(TwelveTheme.appFont(size: 16))
                            Spacer(minLength: 10)
                            if appearance.preference == option {
                                Image(systemName: "checkmark")
                                    .font(TwelveTheme.appFont(size: 14, weight: .semibold))
                                    .foregroundStyle(TwelveTheme.primaryBlue)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .font(TwelveTheme.appFont(size: 20, weight: .medium))
                    .foregroundStyle(TwelveTheme.primaryBlue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Appearance")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var diaryListSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if entries.isEmpty {
                Text("No diary yet. Tap + to start writing.")
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
            Image(systemName: "plus")
                .font(TwelveTheme.appFont(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [TwelveTheme.primaryBlue, TwelveTheme.primaryBlueDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: TwelveTheme.primaryBlue.opacity(0.3), radius: 12, y: 7)
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

#Preview {
    ContentView()
        .environmentObject(AppearanceStore())
}
