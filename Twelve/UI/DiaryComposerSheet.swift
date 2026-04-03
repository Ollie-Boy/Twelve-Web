import SwiftUI
import PhotosUI
import AVFoundation
import MapKit
import CoreLocation

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
    @State private var emotion: String = ""
    @State private var tagText: String = ""
    @State private var location: String = ""
    @State private var attachments: [DiaryAttachment] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedVideoItems: [PhotosPickerItem] = []
    @State private var showAudioRecorder = false
    @State private var showMapPicker = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showWeatherPicker = false
    @State private var datePickerDraftDate: Date = Date()
    @State private var timePickerDraftDate: Date = Date()
    @State private var datePickerDisplayedMonthStart: Date = DiaryComposerSheet.monthAnchor(for: Date())
    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool

    private let attachmentService = AttachmentService()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Title", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                        .submitLabel(.done)
                        .focused($titleFocused)
                        .onSubmit {
                            titleFocused = false
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .wiggleOnInputChange(titleText)

                    HStack(alignment: .center, spacing: 8) {
                        Text("Date & Time")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer(minLength: 6)

                        Button {
                            dismissKeyboard()
                            let cal = Calendar.current
                            let start = cal.startOfDay(for: entryDate)
                            datePickerDraftDate = start
                            datePickerDisplayedMonthStart = Self.monthAnchor(for: start)
                            showDatePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(dateFormatter.string(from: entryDate))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .font(TwelveTheme.appFont(size: 14, weight: .medium))
                            .foregroundStyle(TwelveTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .layoutPriority(1)

                        Button {
                            dismissKeyboard()
                            timePickerDraftDate = entryDate
                            showTimePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                Text(timeFormatter.string(from: entryDate))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .font(TwelveTheme.appFont(size: 14, weight: .medium))
                            .foregroundStyle(TwelveTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .layoutPriority(1)

                        Button("Now") {
                            entryDate = Date()
                            dismissKeyboard()
                        }
                        .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
                        .fixedSize(horizontal: true, vertical: false)
                    }

                    HStack {
                        Text("Weather")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Spacer()
                        Button {
                            dismissKeyboard()
                            showWeatherPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: weather.symbolName)
                                Text(weather.title)
                            }
                            .font(TwelveTheme.appFont(size: 14, weight: .medium))
                            .foregroundStyle(TwelveTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emotion")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("e.g. calm, excited, tired", text: $emotion)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .wiggleOnInputChange(emotion)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("e.g. work", text: $tagText)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .wiggleOnInputChange(tagText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(TwelveTheme.textSecondary)
                                Text(location.isEmpty ? "No address selected" : location)
                                    .font(TwelveTheme.appFont(size: 13))
                                    .foregroundStyle(location.isEmpty ? TwelveTheme.textTertiary : TwelveTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            HStack(spacing: 8) {
                                Button("Use Current") {
                                    dismissKeyboard()
                                    locationManager.requestCurrentLocation()
                                }
                                .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.surfaceTintBlue))

                                Button("Pick on Map") {
                                    dismissKeyboard()
                                    showMapPicker = true
                                }
                                .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))

                                if !location.isEmpty {
                                    Button("No Address") {
                                        location = ""
                                        weather = .none
                                    }
                                    .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softYellow))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Content")
                                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                                .foregroundStyle(TwelveTheme.textSecondary)
                            Spacer()
                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
                                Text("Photo")
                            }
                            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
                            PhotosPicker(selection: $selectedVideoItems, maxSelectionCount: 5, matching: .videos) {
                                Text("Video")
                            }
                            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
                            Button("Audio") {
                                dismissKeyboard()
                                showAudioRecorder = true
                            }
                            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
                        }
                        WiggleTextEditor(text: $bodyText)
                            .frame(minHeight: 180)
                            .focused($bodyFocused)
                    }

                    if !attachments.isEmpty {
                        attachmentsSection
                    }
                }
                .padding(18)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(modeTitle)
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                }
            }
            .onAppear { configureFromMode() }
            .onReceive(locationManager.$currentLocationText) { newValue in
                guard !newValue.isEmpty else { return }
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.localizedCaseInsensitiveContains("error"),
                      !trimmed.localizedCaseInsensitiveContains("denied"),
                      !trimmed.localizedCaseInsensitiveContains("unavailable"),
                      !trimmed.localizedCaseInsensitiveContains("location found")
                else { return }
                location = trimmed
                weather = WeatherOption.suggestedForRecognizedAddress(trimmed, date: entryDate)
            }
            .onChange(of: selectedPhotoItems) { items in
                Task {
                    await importPhotos(from: items)
                    selectedPhotoItems = []
                }
            }
            .onChange(of: selectedVideoItems) { items in
                Task {
                    await importVideos(from: items)
                    selectedVideoItems = []
                }
            }
            .sheet(isPresented: $showAudioRecorder) {
                AudioRecorderSheet { recordedURL in
                    if let attachment = try? attachmentService.importFile(from: recordedURL) {
                        attachments.append(attachment)
                    }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                ComposerLocationPickerSheet(
                    onPickAddress: { address in
                        location = address
                        weather = WeatherOption.suggestedForRecognizedAddress(address, date: entryDate)
                    },
                    onClearAddress: {
                        location = ""
                        weather = .none
                    }
                )
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    ScrollView {
                        CartoonMonthCalendar(
                            selectedDay: Binding(
                                get: { Calendar.current.startOfDay(for: datePickerDraftDate) },
                                set: { datePickerDraftDate = $0 }
                            ),
                            displayedMonthStart: $datePickerDisplayedMonthStart,
                            entryDates: []
                        )
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .padding(.horizontal, 18)
                    .background(TwelveTheme.background)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(TwelveTheme.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Choose Date")
                                .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                                .foregroundStyle(TwelveTheme.textPrimary)
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showDatePicker = false }
                                .font(TwelveTheme.appFont(size: 17))
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                let calendar = Calendar.current
                                let dateParts = calendar.dateComponents([.year, .month, .day], from: datePickerDraftDate)
                                let timeParts = calendar.dateComponents([.hour, .minute], from: entryDate)
                                var merged = DateComponents()
                                merged.year = dateParts.year
                                merged.month = dateParts.month
                                merged.day = dateParts.day
                                merged.hour = timeParts.hour
                                merged.minute = timeParts.minute
                                if let updated = calendar.date(from: merged) {
                                    entryDate = updated
                                }
                                showDatePicker = false
                            }
                            .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        }
                    }
                }
                .font(TwelveTheme.appFont(size: 16))
                .presentationDetents([.height(580), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTimePicker) {
                NavigationStack {
                    ZStack {
                        TwelveTheme.background
                            .ignoresSafeArea()
                        TwelveAppWheelDatePicker(
                            selection: $timePickerDraftDate,
                            mode: .time,
                            minuteInterval: 1
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 232)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TwelveTheme.background)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(TwelveTheme.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Choose Time")
                                .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                                .foregroundStyle(TwelveTheme.textPrimary)
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showTimePicker = false }
                                .font(TwelveTheme.appFont(size: 17))
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: timePickerDraftDate)
                                if let updated = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: entryDate) {
                                    entryDate = updated
                                }
                                showTimePicker = false
                            }
                            .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        }
                    }
                }
                .font(TwelveTheme.appFont(size: 16))
                .presentationDetents([.height(320), .fraction(0.4)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showWeatherPicker) {
                NavigationStack {
                    List {
                        ForEach(WeatherOption.allCases) { item in
                            Button {
                                weather = item
                                showWeatherPicker = false
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: item.symbolName)
                                        .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                                    Text(item.title)
                                        .font(TwelveTheme.appFont(size: 16))
                                    Spacer()
                                    if item == weather {
                                        Image(systemName: "checkmark")
                                            .font(TwelveTheme.appFont(size: 14, weight: .bold))
                                            .foregroundStyle(TwelveTheme.primaryBlueDark)
                                    }
                                }
                                .foregroundStyle(TwelveTheme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Choose Weather")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showWeatherPicker = false }
                                .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        }
                    }
                }
                .font(TwelveTheme.appFont(size: 16))
                .presentationDetents([.fraction(0.45), .medium])
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .gesture(
                TapGesture().onEnded {
                    dismissKeyboard()
                },
                including: .gesture
            )
        }
        // Root app uses handwritten body font; reset here so lists and nav use rounded UI typography.
        .font(TwelveTheme.appFont(size: 16))
    }

    private var modeTitle: String {
        switch mode {
        case .create:
            return "New Entry"
        case .edit:
            return "Edit Entry"
        }
    }

    private static func monthAnchor(for date: Date) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let c = cal.dateComponents([.year, .month], from: day)
        return cal.date(from: c) ?? day
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                attachmentRow(for: attachment)
            }
        }
    }

    private func attachmentRow(for attachment: DiaryAttachment) -> some View {
        let label = attachmentLabel(attachment)
        return HStack {
            Image(systemName: attachment.kind.iconName)
            Text(label)
                .lineLimit(1)
            Spacer()
            Button(role: .destructive) {
                attachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .font(TwelveTheme.appFont(size: 13))
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func configureFromMode() {
        switch mode {
        case .create:
            titleText = ""
            bodyText = ""
            entryDate = Date()
            weather = .none
            emotion = ""
            tagText = ""
            location = ""
            attachments = []
        case .edit(let entry):
            titleText = entry.title
            bodyText = entry.body
            entryDate = entry.selectedDate
            weather = entry.weather
            emotion = entry.emotion ?? ""
            tagText = entry.tags.first ?? ""
            let existingLocation = entry.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            location = existingLocation
            attachments = entry.attachments
        }
    }

    private func save() {
        dismissKeyboard()
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Day" : titleText
        let resolvedEmotion = emotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTag = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTags = resolvedTag.isEmpty ? [] : [resolvedTag]
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
                tags: resolvedTags,
                emotion: resolvedEmotion.isEmpty ? nil : resolvedEmotion,
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
                tags: resolvedTags,
                emotion: resolvedEmotion.isEmpty ? nil : resolvedEmotion,
                attachments: attachments
            )
        }
        onSave(entry)
        isPresented = false
    }

    private func dismissKeyboard() {
        bodyFocused = false
        titleFocused = false
    }

    private func attachmentLabel(_ attachment: DiaryAttachment) -> String {
        switch attachment.kind {
        case .image, .gif:
            return "Image"
        case .video:
            return "Video"
        case .audio:
            return "Audio"
        default:
            return "File"
        }
    }

    private func importPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        var imported: [DiaryAttachment] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
            let fileName = "photo_\(UUID().uuidString).\(ext)"
            if let attachment = try? attachmentService.importData(data, fileName: fileName, kind: .image) {
                imported.append(attachment)
            }
        }
        attachments.append(contentsOf: imported)
    }

    private func importVideos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        var imported: [DiaryAttachment] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "mov"
            let fileName = "video_\(UUID().uuidString).\(ext)"
            if let attachment = try? attachmentService.importData(data, fileName: fileName, kind: .video) {
                imported.append(attachment)
            }
        }
        attachments.append(contentsOf: imported)
    }
}

private struct AudioRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (URL) -> Void
    @StateObject private var recorder = AudioRecorderController()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(recorder.isRecording ? "Recording..." : "Tap to start recording")
                    .font(TwelveTheme.appFont(size: 16, weight: .medium))
                    .foregroundStyle(TwelveTheme.textPrimary)

                Text(recorder.elapsedText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(TwelveTheme.textPrimary)

                Button {
                    recorder.toggleRecording()
                } label: {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(TwelveTheme.appFont(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 86, height: 86)
                        .background(recorder.isRecording ? Color.red : TwelveTheme.primaryBlue, in: Circle())
                }

                if let errorText = recorder.errorMessage, !errorText.isEmpty {
                    Text(errorText)
                        .font(TwelveTheme.appFont(size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .navigationTitle("Record Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        recorder.cancelAndDiscard()
                        dismiss()
                    }
                    .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Insert") {
                        recorder.stopRecording()
                        if let url = recorder.recordedURL {
                            onSave(url)
                        }
                        dismiss()
                    }
                    .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                    .disabled(recorder.recordedURL == nil && !recorder.isRecording)
                }
            }
            .onAppear {
                recorder.requestPermission()
            }
            .onDisappear {
                recorder.stopRecording()
            }
        }
    }
}

private final class AudioRecorderController: ObservableObject {
    @Published var isRecording = false
    @Published var recordedURL: URL?
    @Published var errorMessage: String?
    @Published var elapsedSeconds: Int = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    var elapsedText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.errorMessage = "Microphone permission is required to record audio."
                }
            }
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("diary_audio_\(UUID().uuidString).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.record()
            self.recorder = recorder
            self.recordedURL = nil
            self.errorMessage = nil
            self.elapsedSeconds = 0
            self.isRecording = true
            startTimer()
        } catch {
            errorMessage = "Unable to start recording."
        }
    }

    func stopRecording() {
        guard isRecording || recorder != nil else { return }
        recorder?.stop()
        if let url = recorder?.url {
            recordedURL = url
        }
        recorder = nil
        isRecording = false
        stopTimer()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func cancelAndDiscard() {
        stopRecording()
        if let url = recordedURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordedURL = nil
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
