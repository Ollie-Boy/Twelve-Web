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

                        HStack(spacing: 12) {
                            Button {
                                dismissKeyboard()
                                showDatePicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                    Text(dateFormatter.string(from: entryDate))
                                        .lineLimit(1)
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(BreezyTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                dismissKeyboard()
                                showTimePicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                    Text(timeFormatter.string(from: entryDate))
                                        .lineLimit(1)
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(BreezyTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)

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
                        Text("Emotion")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)
                        TextField("e.g. calm, excited, tired", text: $emotion)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)
                        TextField("e.g. work", text: $tagText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BreezyTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(BreezyTheme.textSecondary)
                                Text(location.isEmpty ? "No address selected" : location)
                                    .font(.system(size: 13))
                                    .foregroundStyle(location.isEmpty ? BreezyTheme.textTertiary : BreezyTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            HStack(spacing: 8) {
                                Button("Use Current") {
                                    dismissKeyboard()
                                    locationManager.requestCurrentLocation()
                                }
                                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.surfaceTintBlue))

                                Button("Pick on Map") {
                                    dismissKeyboard()
                                    showMapPicker = true
                                }
                                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))

                                if !location.isEmpty {
                                    Button("No Address") {
                                        location = ""
                                        weather = .none
                                    }
                                    .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softYellow))
                                }
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
                        attachmentsSection
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
                    VStack {
                        DatePicker(
                            "Date",
                            selection: $entryDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(BreezyTheme.primaryBlueDark.opacity(0.75))
                        Spacer()
                    }
                    .padding(18)
                    .navigationTitle("Choose Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDatePicker = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showTimePicker) {
                NavigationStack {
                    VStack {
                        DatePicker(
                            "Time",
                            selection: $entryDate,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(BreezyTheme.primaryBlueDark.opacity(0.75))
                        Spacer()
                    }
                    .padding(18)
                    .navigationTitle("Choose Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTimePicker = false }
                        }
                    }
                }
                .presentationDetents([.fraction(0.35)])
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
        .font(.system(size: 13))
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

private struct ComposerLocationPickerSheet: View {
    var onPickAddress: (String) -> Void
    var onClearAddress: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pickedAddressText = ""
    @State private var isResolving = false
    @State private var errorText: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            ZStack {
                ComposerLegacyMapView(
                    region: $region,
                    selectedCoordinate: $selectedCoordinate,
                    onTapCoordinate: { coordinate in
                        selectedCoordinate = coordinate
                        resolveAddress(for: coordinate, shouldDismiss: false)
                    }
                )
                    .ignoresSafeArea(edges: .bottom)

                VStack {
                    Text("Tap map to select an exact point, then confirm")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BreezyTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())

                    if isResolving {
                        ProgressView()
                    } else if let errorText {
                        Text(errorText)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    } else if !pickedAddressText.isEmpty {
                        Text(pickedAddressText)
                            .font(.system(size: 12))
                            .foregroundStyle(BreezyTheme.textPrimary)
                            .lineLimit(2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()
                }
                .padding(.top, 10)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Button {
                                useCurrentLocation()
                            } label: {
                                Image(systemName: "location.fill")
                                    .frame(width: 36, height: 36)
                                    .background(BreezyTheme.surface, in: Circle())
                            }
                            Button {
                                useMapCenter()
                            } label: {
                                Image(systemName: "checkmark")
                                    .frame(width: 36, height: 36)
                                    .background(BreezyTheme.primaryBlue, in: Circle())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(14)
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("No Address") {
                        onClearAddress()
                        dismiss()
                    }
                }
            }
            .onAppear {
                useCurrentLocation()
            }
        }
    }

    private func useCurrentLocation() {
        if let coordinate = LocationStore.shared.lastCoordinate {
            selectedCoordinate = coordinate
            region.center = coordinate
        }
    }

    private func useMapCenter() {
        let target = selectedCoordinate ?? region.center
        resolveAddress(for: target, shouldDismiss: true)
    }

    private func resolveAddress(for coordinate: CLLocationCoordinate2D, shouldDismiss: Bool = true) {
        errorText = nil
        isResolving = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            isResolving = false
            if let error {
                errorText = error.localizedDescription
                return
            }
            guard let placemark = placemarks?.first else {
                errorText = "Address unavailable"
                return
            }
            let parts = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
            let address = parts.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            guard !address.isEmpty else {
                errorText = "Address unavailable"
                return
            }
            pickedAddressText = address
            if shouldDismiss {
                onPickAddress(address)
                dismiss()
            }
        }
    }
}

private struct ComposerLegacyMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    var onTapCoordinate: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsCompass = true
        map.showsScale = false
        map.setRegion(region, animated: false)
        map.delegate = context.coordinator
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        map.addGestureRecognizer(tapRecognizer)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self
        if abs(uiView.region.center.latitude - region.center.latitude) > 0.00001
            || abs(uiView.region.center.longitude - region.center.longitude) > 0.00001
        {
            uiView.setRegion(region, animated: false)
        }

        let existingPins = uiView.annotations.filter { !($0 is MKUserLocation) }
        if let selectedCoordinate {
            uiView.removeAnnotations(existingPins)
            let pin = MKPointAnnotation()
            pin.coordinate = selectedCoordinate
            uiView.addAnnotation(pin)
        } else if !existingPins.isEmpty {
            uiView.removeAnnotations(existingPins)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ComposerLegacyMapView
        init(parent: ComposerLegacyMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView else { return }
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.selectedCoordinate = coordinate
            parent.onTapCoordinate?(coordinate)
        }
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
