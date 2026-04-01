import SwiftUI
import PhotosUI
import AVFoundation

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
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedVideoItems: [PhotosPickerItem] = []
    @State private var showAudioRecorder = false
    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool
    @FocusState private var locationFocused: Bool

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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)

                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .foregroundStyle(BreezyTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: $entryDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(BreezyTheme.primaryBlueDark.opacity(0.75))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        HStack(spacing: 10) {
                            Image(systemName: "clock")
                                .foregroundStyle(BreezyTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: $entryDate,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(BreezyTheme.primaryBlueDark.opacity(0.75))
                            Spacer()
                            Button("Now") {
                                entryDate = Date()
                                dismissKeyboard()
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

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
                            TextField("No address selected", text: $location)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundStyle(BreezyTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .focused($locationFocused)

                            Button {
                                dismissKeyboard()
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
                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
                                Text("Photo")
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                            PhotosPicker(selection: $selectedVideoItems, maxSelectionCount: 5, matching: .videos) {
                                Text("Video")
                            }
                            .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))
                            Button("Audio") {
                                dismissKeyboard()
                                showAudioRecorder = true
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
                                    Text(attachmentLabel(attachment))
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
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .gesture(
                TapGesture().onEnded {
                    dismissKeyboard()
                },
                including: .gesture
            )
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
        dismissKeyboard()
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

    private func dismissKeyboard() {
        bodyFocused = false
        titleFocused = false
        locationFocused = false
    }

    private func attachmentLabel(_ attachment: DiaryAttachment) -> String {
        switch attachment.kind {
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .audio:
            return "Audio"
        case .gif:
            return "GIF"
        case .markdown:
            return "Markdown"
        case .latex:
            return "LaTeX"
        case .document:
            return "Document"
        case .other:
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BreezyTheme.textPrimary)

                Text(recorder.elapsedText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(BreezyTheme.textPrimary)

                Button {
                    recorder.toggleRecording()
                } label: {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 86, height: 86)
                        .background(recorder.isRecording ? Color.red : BreezyTheme.primaryBlue, in: Circle())
                }

                if let errorText = recorder.errorMessage, !errorText.isEmpty {
                    Text(errorText)
                        .font(.system(size: 13))
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
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Insert") {
                        recorder.stopRecording()
                        if let url = recorder.recordedURL {
                            onSave(url)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
