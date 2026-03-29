import SwiftUI
import UniformTypeIdentifiers

struct DiaryComposerSheet: View {
    enum Mode {
        case create
        case edit(DiaryEntry)
    }

    let mode: Mode
    let onSave: (DiaryEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locationManager = LocationManager()
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    @State private var entryDate: Date = Date()
    @State private var weather: WeatherOption = .sunny
    @State private var location: String = ""
    @State private var hasLocation = false
    @State private var attachments: [DiaryAttachment] = []
    @State private var showMediaPicker = false
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack {
                        DatePicker(
                            "",
                            selection: $entryDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .tint(.primary)

                        Spacer()

                        Button("Now") {
                            entryDate = Date()
                            bodyFocused = false
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

                        HStack(spacing: 8) {
                            Button("Use Current Place") {
                                bodyFocused = false
                                locationManager.requestCurrentLocation()
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.surfaceTintBlue))

                            if hasLocation {
                                Button("Clear") {
                                    location = ""
                                    hasLocation = false
                                }
                                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softYellow))
                            }
                        }

                        if hasLocation {
                            Text(location)
                                .font(.system(size: 13))
                                .foregroundStyle(BreezyTheme.textSecondary)
                        } else {
                            Text("No location selected")
                                .font(.system(size: 13))
                                .foregroundStyle(BreezyTheme.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Content")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BreezyTheme.textSecondary)
                            Spacer()
                            Button("Add File") {
                                bodyFocused = false
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { configureFromMode() }
            .onReceive(locationManager.$currentLocationText) { newValue in
                guard !newValue.isEmpty else { return }
                location = newValue
                hasLocation = !newValue.contains("error") && !newValue.contains("denied")
            }
            .sheet(isPresented: $showMediaPicker) {
                MediaPicker { pickedURLs in
                    attachments.append(contentsOf: attachmentService.importPickedFiles(pickedURLs))
                }
            }
            .onSubmit { bodyFocused = false }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        bodyFocused = false
                    }
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
            hasLocation = false
            attachments = []
        case .edit(let entry):
            titleText = entry.title
            bodyText = entry.body
            entryDate = entry.selectedDate
            weather = entry.weather
            location = entry.location
            hasLocation = !entry.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            attachments = entry.attachments
        }
    }

    private func save() {
        bodyFocused = false
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Day" : titleText
        let resolvedLocation = hasLocation ? location : ""
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
        dismiss()
    }
}
