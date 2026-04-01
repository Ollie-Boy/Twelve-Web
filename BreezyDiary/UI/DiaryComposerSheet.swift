import SwiftUI
import UniformTypeIdentifiers

struct DiaryComposerSheet: View {
    enum Mode {
        case create
        case edit(DiaryEntry)
    }

    @Binding var isPresented: Bool
    let mode: Mode
    let onSave: (DiaryEntry) -> Void

    @StateObject private var locationManager = LocationManager()
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    @State private var entryDate: Date = Date()
    @State private var weather: WeatherOption = .sunny
    @State private var location: String = ""
    @State private var attachments: [DiaryAttachment] = []
    @State private var showMediaPicker = false
    @State private var pickerKind: MediaPicker.Kind = .photo
    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool

    private let attachmentService = AttachmentService()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Title", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .semibold))
                        .submitLabel(.done)
                        .focused($titleFocused)
                        .onSubmit {
                            titleFocused = false
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(BreezyTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: $entryDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .foregroundStyle(BreezyTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: $entryDate,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }

                        Spacer()

                        Button("Now") {
                            entryDate = Date()
                            bodyFocused = false
                            titleFocused = false
                        }
                        .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                    }
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)

                    Text(dateFormatter.string(from: entryDate))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(BreezyTheme.textSecondary)

                    HStack {
                        Text("Weather")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)
                        Spacer()
                        Picker("Weather", selection: $weather) {
                            ForEach(WeatherOption.allCases) { item in
                                Text(item.title)
                                    .foregroundStyle(.black)
                                    .tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)

                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(BreezyTheme.textSecondary)
                            Text(location.isEmpty ? "No address selected" : location)
                                .font(.system(size: 13))
                                .foregroundStyle(location.isEmpty ? BreezyTheme.textTertiary : BreezyTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                titleFocused = false
                                bodyFocused = false
                                locationManager.requestCurrentLocation()
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(BreezyTheme.primaryBlueDark)
                                    .frame(width: 30, height: 30)
                                    .background(BreezyTheme.surfaceTintBlue, in: Circle())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Content")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BreezyTheme.textSecondary)
                            Spacer()
                            Button("Photo") {
                                titleFocused = false
                                bodyFocused = false
                                pickerKind = .photo
                                showMediaPicker = true
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                            Button("Video") {
                                titleFocused = false
                                bodyFocused = false
                                pickerKind = .video
                                showMediaPicker = true
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                            Button("Audio") {
                                titleFocused = false
                                bodyFocused = false
                                pickerKind = .audio
                                showMediaPicker = true
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                        }
                        WiggleTextEditor(text: $bodyText)
                            .frame(minHeight: 180)
                            .focused($bodyFocused)
                    }

                    if !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Attachments")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BreezyTheme.textSecondary)
                            ForEach(attachments) { attachment in
                                HStack {
                                    Image(systemName: attachment.kind.iconName)
                                    Text(attachment.displayName)
                                        .lineLimit(1)
                                    Spacer()
                                    Button(role: .destructive) {
                                        attachments.removeAll { $0.id == attachment.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                }
                                .font(.system(size: 13))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(18)
            }
            .navigationTitle(modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { configureFromMode() }
            .onReceive(locationManager.$currentLocationText) { newValue in
                guard !newValue.isEmpty else { return }
                if !newValue.localizedCaseInsensitiveContains("error")
                    && !newValue.localizedCaseInsensitiveContains("denied")
                {
                    location = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            .sheet(isPresented: $showMediaPicker) {
                MediaPicker(kind: pickerKind) { pickedURLs in
                    attachments.append(contentsOf: attachmentService.importPickedFiles(pickedURLs))
                }
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create:
            return "New Entry"
        case .edit:
            return "Edit Entry"
        }
    }

    private func configureFromMode() {
        switch mode {
        case .create:
            titleText = ""
            bodyText = ""
            entryDate = Date()
            weather = .none
            location = ""
            attachments = []
        case .edit(let entry):
            titleText = entry.title
            bodyText = entry.body
            entryDate = entry.selectedDate
            weather = entry.weather
            let existingLocation = entry.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            location = existingLocation
            attachments = entry.attachments
        }
    }

    private func save() {
        bodyFocused = false
        titleFocused = false
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Day" : titleText
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedLocation = trimmedLocation.isEmpty ? nil : trimmedLocation
        let markdownBody = bodyText

        let entry: DiaryEntry
        switch mode {
        case .create:
            entry = DiaryEntry(
                id: UUID(),
                createdAt: Date(),
                selectedDate: entryDate,
                title: title,
                body: markdownBody,
                weather: weather,
                location: resolvedLocation,
                attachments: attachments
            )
        case .edit(let existing):
            entry = DiaryEntry(
                id: existing.id,
                createdAt: existing.createdAt,
                selectedDate: entryDate,
                title: title,
                body: markdownBody,
                weather: weather,
                location: resolvedLocation,
                attachments: attachments
            )
        }
        onSave(entry)
        isPresented = false
    }
}
