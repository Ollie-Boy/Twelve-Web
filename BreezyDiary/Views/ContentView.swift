import SwiftUI

enum LocationMode: Hashable {
    case currentLocation
    case manualInput
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var entries: [DiaryEntry] = []
    @State private var editingEntryID: UUID?
    @State private var pendingDeletionEntry: DiaryEntry?
    @State private var isFeatureCardPresented: Bool = true

    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    @State private var entryDate: Date = Date()
    @State private var weather: WeatherOption = .sunny
    @State private var locationMode: LocationMode = .currentLocation
    @State private var manualLocation: String = ""
    @State private var locationText: String = "Unknown Place"

    private let storage = DiaryStorage()
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ZStack {
            BreezyTheme.background.ignoresSafeArea()
            WindyBackgroundView()

            ScrollView {
                VStack(spacing: 22) {
                    heroSection
                    editorSection
                    entriesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
            }

            if isFeatureCardPresented {
                TodayFeatureCardOverlay(isPresented: $isFeatureCardPresented)
                    .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
                    .zIndex(10)
            }
        }
        .onAppear {
            entries = storage.loadEntries()
            sortEntries()
        }
        .onReceive(locationManager.$currentLocationText) { coordinateText in
            if locationMode == .currentLocation {
                locationText = coordinateText
            }
        }
        .alert(item: $pendingDeletionEntry) { entry in
            Alert(
                title: Text("Delete this entry?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteEntry(entry)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breezy Diary")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(BreezyTheme.textPrimary)
            Text("Write gentle moments with a calm, Apple-style layout.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(BreezyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isEditing ? "Edit Entry" : "New Entry")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(BreezyTheme.textPrimary)
                Spacer()
                if isEditing {
                    Button("Cancel", action: cancelEditing)
                        .buttonStyle(BreezyPillButtonStyle())
                }
            }

            TextField("Title", text: $titleText)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Date & Time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BreezyTheme.textSecondary)
                    DatePicker(
                        "Entry Date",
                        selection: $entryDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }

                Spacer()

                Button("Now") {
                    entryDate = Date()
                }
                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.surfaceTintBlue))
            }

            Text(displayFormatter.string(from: entryDate))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(BreezyTheme.textSecondary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weather")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BreezyTheme.textSecondary)
                    Picker("Weather", selection: $weather) {
                        ForEach(WeatherOption.allCases) { item in
                            Label(item.title, systemImage: item.symbolName)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Location Mode")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BreezyTheme.textSecondary)
                    Picker("Location Source", selection: $locationMode) {
                        Text("Current").tag(LocationMode.currentLocation)
                        Text("Manual").tag(LocationMode.manualInput)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                }
            }

            Group {
                if locationMode == .currentLocation {
                    HStack(spacing: 10) {
                        Label(locationText, systemImage: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(BreezyTheme.textSecondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Refresh") {
                            locationManager.requestCurrentLocation()
                        }
                        .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.accentYellow))
                    }
                } else {
                    TextField("Location", text: $manualLocation)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .regular))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Diary")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BreezyTheme.textSecondary)
                WiggleTextEditor(text: $bodyText)
                    .frame(height: 170)
            }

            Button {
                saveEntry()
            } label: {
                Text(isEditing ? "Update Entry" : "Save Entry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BreezyPrimaryButtonStyle())
            .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(20)
        .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(BreezyTheme.hairline, lineWidth: 1)
        )
        .shadow(color: BreezyTheme.shadow, radius: 20, y: 10)
        .onChange(of: locationMode) { newMode in
            if newMode == .currentLocation {
                locationText = locationManager.currentLocationText
            }
        }
        .onAppear {
            locationManager.requestCurrentLocation()
        }
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Entries")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(BreezyTheme.textPrimary)

            if entries.isEmpty {
                Text("No entries yet. Write your first one above.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BreezyTheme.hairline, lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        EntryCardView(
                            entry: entry,
                            onEdit: { beginEditing(entry) },
                            onDelete: { pendingDeletionEntry = entry }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isEditing: Bool {
        editingEntryID != nil
    }

    private func saveEntry() {
        let resolvedLocation: String
        if locationMode == .manualInput {
            let trimmed = manualLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            resolvedLocation = trimmed.isEmpty ? "Unknown Place" : trimmed
        } else {
            resolvedLocation = locationText
        }

        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = trimmedTitle.isEmpty ? "Untitled Day" : trimmedTitle

        if let editingEntryID, let index = entries.firstIndex(where: { $0.id == editingEntryID }) {
            entries[index].selectedDate = entryDate
            entries[index].title = normalizedTitle
            entries[index].body = bodyText
            entries[index].weather = weather
            entries[index].location = resolvedLocation
        } else {
            let entry = DiaryEntry(
                id: UUID(),
                createdAt: Date(),
                selectedDate: entryDate,
                title: normalizedTitle,
                body: bodyText,
                weather: weather,
                location: resolvedLocation
            )
            entries.insert(entry, at: 0)
        }

        sortEntries()
        storage.saveEntries(entries)
        clearEditor(keepLocationMode: false)
    }

    private func beginEditing(_ entry: DiaryEntry) {
        editingEntryID = entry.id
        titleText = entry.title
        bodyText = entry.body
        entryDate = entry.selectedDate
        weather = entry.weather
        locationMode = .manualInput
        manualLocation = entry.location
        locationText = entry.location
    }

    private func cancelEditing() {
        clearEditor(keepLocationMode: false)
    }

    private func deleteEntry(_ entry: DiaryEntry) {
        entries.removeAll { $0.id == entry.id }
        storage.saveEntries(entries)
        if editingEntryID == entry.id {
            clearEditor(keepLocationMode: false)
        }
    }

    private func clearEditor(keepLocationMode: Bool) {
        editingEntryID = nil
        titleText = ""
        bodyText = ""
        manualLocation = ""
        entryDate = Date()
        weather = .sunny
        if !keepLocationMode {
            locationMode = .currentLocation
            locationText = locationManager.currentLocationText
        }
    }

    private func sortEntries() {
        entries.sort { $0.selectedDate > $1.selectedDate }
    }
}

#Preview {
    ContentView()
}
