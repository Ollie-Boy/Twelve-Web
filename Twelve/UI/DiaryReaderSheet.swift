import QuickLook
import SwiftUI
import AVKit
import UIKit

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct DiaryReaderPagerSheet: View {
    let entries: [DiaryEntry]
    let initialEntryID: UUID
    let onEdit: (DiaryEntry) -> Void
    let onDelete: (DiaryEntry) -> Void

    private let sortedEntries: [DiaryEntry]
    @State private var currentIndex: Int = 0

    init(entries: [DiaryEntry], initialEntryID: UUID, onEdit: @escaping (DiaryEntry) -> Void, onDelete: @escaping (DiaryEntry) -> Void) {
        self.entries = entries
        self.initialEntryID = initialEntryID
        self.onEdit = onEdit
        self.onDelete = onDelete
        let sorted = entries.sorted { $0.selectedDate > $1.selectedDate }
        self.sortedEntries = sorted
        let initialIndex = sorted.firstIndex(where: { $0.id == initialEntryID }) ?? 0
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            if sortedEntries.indices.contains(currentIndex) {
                let currentEntry = sortedEntries[currentIndex]
                DiaryReaderSheet(
                    entry: currentEntry,
                    onHorizontalSwipe: handleHorizontalSwipe,
                    onEdit: { onEdit(currentEntry) },
                    onDelete: { onDelete(currentEntry) }
                )
                .id(currentEntry.id)
                .transition(.opacity)
            } else {
                Text("No entry available")
                    .font(TwelveTheme.appFont(size: 16))
            }
        }
        .animation(.easeOut(duration: 0.18), value: currentIndex)
    }

    private func handleHorizontalSwipe(_ width: CGFloat) {
        guard abs(width) > 42 else { return }
        if width < 0 {
            let next = currentIndex + 1
            guard sortedEntries.indices.contains(next) else { return }
            currentIndex = next
        } else {
            let previous = currentIndex - 1
            guard sortedEntries.indices.contains(previous) else { return }
            currentIndex = previous
        }
    }
}

struct DiaryReaderSheet: View {
    let entry: DiaryEntry
    var onHorizontalSwipe: ((CGFloat) -> Void)? = nil
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var quickLookURL: URL?
    @State private var selectedImageURL: URL?

    private var imageAttachments: [DiaryAttachment] {
        entry.attachments.filter { $0.kind == .image || $0.kind == .gif }
    }

    private var nonImageAttachments: [DiaryAttachment] {
        entry.attachments.filter { $0.kind != .image && $0.kind != .gif }
    }

    private var trimmedEmotion: String {
        entry.emotion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !imageAttachments.isEmpty {
                        topImageCarousel
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text(entry.title)
                            .font(TwelveTheme.appFont(size: 30, weight: .bold))
                            .foregroundStyle(TwelveTheme.textPrimary)

                        HStack(spacing: 10) {
                            if entry.weather != .none {
                                Label(entry.weather.title, systemImage: entry.weather.symbolName)
                            }
                            if let location = entry.location, !location.isEmpty {
                                Label(location, systemImage: "mappin.and.ellipse")
                                    .lineLimit(1)
                            }
                        }
                        .font(TwelveTheme.appFont(size: 13))
                        .foregroundStyle(TwelveTheme.textPrimary)

                        Text(entry.selectedDate.formatted(date: .complete, time: .shortened))
                            .font(TwelveTheme.appFont(size: 13))
                            .foregroundStyle(TwelveTheme.textSecondary)

                        if !entry.tags.isEmpty || !trimmedEmotion.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                }
                                if !trimmedEmotion.isEmpty {
                                    Text(trimmedEmotion)
                                }
                            }
                            .font(TwelveTheme.appFont(size: 12, weight: .semibold))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        }

                        if !entry.body.isEmpty {
                            DiaryBodyContentView(text: entry.body)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 24)
                            .onEnded { value in
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                onHorizontalSwipe?(value.translation.width)
                            },
                        including: .gesture
                    )

                    if !nonImageAttachments.isEmpty {
                        nonImageAttachmentSection
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if let onEdit {
                        Button("Edit") {
                            dismiss()
                            onEdit()
                        }
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                    }
                    if let onDelete {
                        Button("Delete", role: .destructive) {
                            dismiss()
                            onDelete()
                        }
                        .font(TwelveTheme.appFont(size: 17))
                    }
                }
            }
            .sheet(item: $quickLookURL) { url in
                QuickLookPreviewControllerRepresentable(url: url)
            }
            .sheet(item: $selectedImageURL) { url in
                FullscreenImageViewer(imageURL: url)
            }
        }
    }

    private var topImageCarousel: some View {
        Group {
            if imageAttachments.count > 1 {
                TabView {
                    ForEach(imageAttachments) { imageItem in
                        Button {
                            selectedImageURL = imageItem.url
                        } label: {
                            readerImageCell(url: imageItem.url)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 240)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            } else if let imageItem = imageAttachments.first {
                Button {
                    selectedImageURL = imageItem.url
                } label: {
                    readerImageCell(url: imageItem.url)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func readerImageCell(url: URL) -> some View {
        if let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            imageLoadFallbackView
        }
    }

    private var nonImageAttachmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(nonImageAttachments) { item in
                VStack(alignment: .leading, spacing: 10) {
                    nonImageMediaPreview(for: item)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TwelveTheme.hairline, lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private func nonImageMediaPreview(for item: DiaryAttachment) -> some View {
        switch item.kind {
        case .video:
            InlineVideoPreview(url: item.url, height: 220)
        case .audio:
            InlineAudioPreview(url: item.url)
        default:
            Button {
                quickLookURL = item.url
            } label: {
                HStack {
                    Image(systemName: item.kind.iconName)
                    Text(item.kind.title)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .font(TwelveTheme.appFont(size: 14, weight: .medium))
                .foregroundStyle(TwelveTheme.textPrimary)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var imageLoadFallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(TwelveTheme.secondarySurface)
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(TwelveTheme.appFont(size: 22, weight: .semibold))
                Text("Unable to load image")
                    .font(TwelveTheme.appFont(size: 13, weight: .medium))
            }
            .foregroundStyle(TwelveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }

}

private struct InlineVideoPreview: View {
    let height: CGFloat
    @State private var player: AVPlayer

    init(url: URL, height: CGFloat) {
        self.height = height
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onDisappear {
                player.pause()
            }
    }
}

private struct InlineAudioPreview: View {
    @State private var player: AVPlayer
    @State private var isPlaying = false

    init(url: URL) {
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(TwelveTheme.appFont(size: 24, weight: .semibold))
                .foregroundStyle(TwelveTheme.primaryBlueDark)
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio")
                    .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textPrimary)
                Text(isPlaying ? "Playing" : "Tap to play")
                    .font(TwelveTheme.appFont(size: 12))
                    .foregroundStyle(TwelveTheme.textSecondary)
            }
            Spacer()
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(TwelveTheme.textSecondary)
                    .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
        }
        .padding(12)
        .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)) { _ in
            isPlaying = false
            player.seek(to: .zero)
        }
        .onAppear {
            player.pause()
            isPlaying = false
        }
        .onDisappear {
            player.pause()
            isPlaying = false
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
}

private struct FullscreenImageViewer: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let image = UIImage(contentsOfFile: imageURL.path) {
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            } else {
                Text("Unable to load image")
                    .foregroundStyle(.white)
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(TwelveTheme.appFont(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(16)
            }
        }
    }
}

private extension DiaryAttachmentKind {
    var title: String {
        switch self {
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .gif:
            return "GIF"
        case .audio:
            return "Audio"
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
}

private struct QuickLookPreviewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let item: NSURL
        init(url: URL) {
            self.item = url as NSURL
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            item
        }
    }
}
