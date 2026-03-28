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
            BreezyTheme.softBlueBackground.ignoresSafeArea()
            WindyBackgroundView()

            ScrollView {
                adaptiveLayout
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
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

    @ViewBuilder
    private var adaptiveLayout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                VStack(spacing: 18) {
                    headerCard
                    editorCard
                }
                .frame(minWidth: 340, idealWidth: 390, maxWidth: 430, alignment: .top)

                historySection
                    .frame(minWidth: 330, maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .top)

            VStack(spacing: 18) {
                headerCard
                editorCard
                historySection
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breezy Diary")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(BreezyTheme.deepBlue)
            Text("A playful offline diary with windy cartoon vibes.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(BreezyTheme.deepBlue.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(BreezyTheme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: BreezyTheme.deepBlue.opacity(0.13), radius: 14, y: 7)
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                Text(isEditing ? "Edit Entry" : "New Entry")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(BreezyTheme.deepBlue)

                TextField("Entry title...", text: $titleText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Time")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreezyTheme.deepBlue)

                DatePicker("Entry Date", selection: $entryDate)
                    .datePickerStyle(.compact)
                    .displayedComponents([.date, .hourAndMinute])
                    .labelsHidden()

                HStack {
                    Text(displayFormatter.string(from: entryDate))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(BreezyTheme.deepBlue.opacity(0.8))
                    Spacer()
                    Button("Use Now") {
                        entryDate = Date()
                    }
                    .buttonStyle(BreezyPillButtonStyle())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Weather")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreezyTheme.deepBlue)

                Picker("Weather", selection: $weather) {
                    ForEach(WeatherOption.allCases) { item in
                        Label(item.title, systemImage: item.symbolName)
                            .tag(item)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreezyTheme.deepBlue)

                Picker("Location Source", selection: $locationMode) {
                    Text("Current Coordinates").tag(LocationMode.currentLocation)
                    Text("Manual Input").tag(LocationMode.manualInput)
                }
                .pickerStyle(.segmented)

                if locationMode == .currentLocation {
                    HStack {
                        Text(locationText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(BreezyTheme.deepBlue.opacity(0.78))
                        Spacer()
                        Button("Refresh") {
                            locationManager.requestCurrentLocation()
                        }
                        .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softYellow))
                    }
                } else {
                    TextField("Type location manually...", text: $manualLocation)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Diary Text")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreezyTheme.deepBlue)

                WiggleTextEditor(text: $bodyText)
                    .frame(height: 180)
            }

            Button {
                saveEntry()
            } label: {
                HStack {
                    Image(systemName: isEditing ? "pencil.circle.fill" : "square.and.arrow.down.fill")
                    Text(isEditing ? "Update Entry" : "Save Entry")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BreezyPrimaryButtonStyle())
            .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if isEditing {
                Button("Cancel Editing") {
                    cancelEditing()
                }
                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.skyBlue))
            }
        }
        .padding(16)
        .background(BreezyTheme.whiteCard)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: BreezyTheme.deepBlue.opacity(0.1), radius: 14, y: 7)
        .onChange(of: locationMode) { newMode in
            if newMode == .currentLocation {
                locationText = locationManager.currentLocationText
            }
        }
        .onAppear {
            locationManager.requestCurrentLocation()
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Entries")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(BreezyTheme.deepBlue)

            if entries.isEmpty {
                Text("No entries yet. Start your first breezy story!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(BreezyTheme.deepBlue.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(BreezyTheme.whiteCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(entries) { entry in
                    EntryCardView(
                        entry: entry,
                        onEdit: { beginEditing(entry) },
                        onDelete: { pendingDeletionEntry = entry }
                    )
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
