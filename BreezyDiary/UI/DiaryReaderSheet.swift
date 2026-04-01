import QuickLook
import SwiftUI
import AVKit
import UIKit
import Foundation

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct DiaryReaderPagerSheet: View {
    let entries: [DiaryEntry]
    let initialEntryID: UUID
    let onEdit: (DiaryEntry) -> Void
    let onDelete: (DiaryEntry) -> Void

    @State private var currentEntryID: UUID

    init(entries: [DiaryEntry], initialEntryID: UUID, onEdit: @escaping (DiaryEntry) -> Void, onDelete: @escaping (DiaryEntry) -> Void) {
        self.entries = entries
        self.initialEntryID = initialEntryID
        self.onEdit = onEdit
        self.onDelete = onDelete
        _currentEntryID = State(initialValue: initialEntryID)
    }

    var body: some View {
        ZStack {
            readerContent
                .id(currentEntryID)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: currentEntryID)
    }

    @ViewBuilder
    private var readerContent: some View {
        if let current = entries.first(where: { $0.id == currentEntryID }) {
            DiaryReaderSheet(
                entry: current,
                allEntries: entries,
                onEdit: { onEdit(current) },
                onDelete: { onDelete(current) },
                onOpenEntry: { next in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        currentEntryID = next.id
                    }
                }
            )
        } else if let fallback = entries.first {
            DiaryReaderSheet(
                entry: fallback,
                allEntries: entries,
                onEdit: { onEdit(fallback) },
                onDelete: { onDelete(fallback) },
                onOpenEntry: { next in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        currentEntryID = next.id
                    }
                }
            )
        } else {
            Text("No entry available")
        }
    }
}

struct DiaryReaderSheet: View {
    let entry: DiaryEntry
    var allEntries: [DiaryEntry] = []
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onOpenEntry: ((DiaryEntry) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var quickLookURL: URL?
    @State private var selectedImageURL: URL?

    private enum BodyBlockItem: Identifiable {
        case text(String, String)
        case media(String, [DiaryAttachment])

        var id: String {
            switch self {
            case .text(let id, _):
                return id
            case .media(let id, _):
                return id
            }
        }
    }

    private enum AttachmentDisplayItem: Identifiable {
        case imageGroup([DiaryAttachment])
        case single(DiaryAttachment)

        var id: String {
            switch self {
            case .imageGroup(let items):
                return "images-\(items.map(\.id.uuidString).joined(separator: "-"))"
            case .single(let item):
                return item.id.uuidString
            }
        }
    }

    private var bodyBlocksToDisplay: [BodyBlockItem] {
        let sourceBlocks: [DiaryContentBlock]
        if entry.contentBlocks.isEmpty {
            sourceBlocks = [DiaryContentBlock(text: entry.body, attachments: entry.attachments)]
        } else {
            sourceBlocks = entry.contentBlocks
        }

        var items: [BodyBlockItem] = []
        for block in sourceBlocks {
            let trimmed = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items.append(.text("\(block.id.uuidString)-text", block.text))
            }
            if !block.attachments.isEmpty {
                items.append(.media("\(block.id.uuidString)-media", block.attachments))
            }
        }
        return items
    }

    private var trimmedEmotion: String {
        entry.emotion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(entry.title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(BreezyTheme.textPrimary)

                    HStack(spacing: 10) {
                        if entry.weather != .none {
                            Label(entry.weather.title, systemImage: entry.weather.symbolName)
                        }
                        if let location = entry.location, !location.isEmpty {
                            Label(location, systemImage: "mappin.and.ellipse")
                                .lineLimit(1)
                        }
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(BreezyTheme.textPrimary)

                    Text(entry.selectedDate.formatted(date: .complete, time: .shortened))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(BreezyTheme.textSecondary)

                    if !entry.tags.isEmpty || !trimmedEmotion.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text("#\(tag)")
                            }
                            if !trimmedEmotion.isEmpty {
                                Text(trimmedEmotion)
                            }
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textSecondary)
                    }

                    ForEach(bodyBlocksToDisplay) { block in
                        switch block {
                        case .text(_, let blockText):
                            MarkdownOrPlainTextView(text: blockText, format: entry.bodyFormat)
                        case .media(_, let attachments):
                            attachmentSection(attachments: attachments)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(BreezyTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if let onEdit {
                        Button("Edit") {
                            dismiss()
                            onEdit()
                        }
                    }
                    if let onDelete {
                        Button("Delete", role: .destructive) {
                            dismiss()
                            onDelete()
                        }
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
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    handleHorizontalSwipe(value.translation.width)
                }
        )
    }

    private func attachmentSection(attachments: [DiaryAttachment]) -> some View {
        let displayAttachments = groupedDisplayAttachments(from: attachments)
        VStack(alignment: .leading, spacing: 10) {
            Text("Attachments")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BreezyTheme.textPrimary)
            ForEach(displayAttachments) { attachment in
                VStack(alignment: .leading, spacing: 10) {
                    mediaPreview(for: attachment)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BreezyTheme.hairline, lineWidth: 1)
                )
            }
        }
    }

    private func groupedDisplayAttachments(from attachments: [DiaryAttachment]) -> [AttachmentDisplayItem] {
        let imageItems = attachments.filter { $0.kind == .image || $0.kind == .gif }
        var items: [AttachmentDisplayItem] = []
        if !imageItems.isEmpty {
            items.append(.imageGroup(imageItems))
        }
        for item in attachments where item.kind != .image && item.kind != .gif {
            items.append(.single(item))
        }
        return items
    }

    @ViewBuilder
    private func mediaPreview(for displayItem: AttachmentDisplayItem) -> some View {
        switch displayItem {
        case .imageGroup(let imageAttachments):
            if imageAttachments.count > 1 {
                TabView {
                    ForEach(imageAttachments) { imageItem in
                        Button {
                            selectedImageURL = imageItem.url
                        } label: {
                            if let image = UIImage(contentsOfFile: imageItem.url.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 220)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            } else {
                let imageItem = imageAttachments[0]
                Button {
                    selectedImageURL = imageItem.url
                } label: {
                    if let image = UIImage(contentsOfFile: imageItem.url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .buttonStyle(.plain)
            }
        case .single(let item):
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleHorizontalSwipe(_ width: CGFloat) {
        guard abs(width) > 40 else { return }
        guard let onOpenEntry else { return }
        let sorted = allEntries.sorted { $0.selectedDate > $1.selectedDate }
        guard let currentIndex = sorted.firstIndex(where: { $0.id == entry.id }) else { return }
        if width < 0 {
            let nextIndex = currentIndex + 1
            if sorted.indices.contains(nextIndex) {
                onOpenEntry(sorted[nextIndex])
            }
        } else {
            let prevIndex = currentIndex - 1
            if sorted.indices.contains(prevIndex) {
                onOpenEntry(sorted[prevIndex])
            }
        }
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
                .font(.system(size: 24))
                .foregroundStyle(BreezyTheme.primaryBlueDark)
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BreezyTheme.textPrimary)
                Text(isPlaying ? "Playing" : "Tap to play")
                    .font(.system(size: 12))
                    .foregroundStyle(BreezyTheme.textSecondary)
            }
            Spacer()
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
        }
        .padding(12)
        .background(BreezyTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(16)
            }
        }
    }
}

private struct MarkdownOrPlainTextView: View {
    let text: String
    let format: DiaryBodyFormat

    var body: some View {
        if format == .latex {
            VStack(alignment: .leading, spacing: 8) {
                Text("LaTeX")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BreezyTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                        .foregroundStyle(BreezyTheme.textPrimary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if format == .html {
            if let htmlAttributed = htmlAttributedString(from: text) {
                Text(AttributedString(htmlAttributed))
                    .font(.system(size: 16))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .textSelection(.enabled)
            } else {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .textSelection(.enabled)
            }
        } else if format == .markdown, let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
                .font(.system(size: 16))
                .foregroundStyle(BreezyTheme.textPrimary)
                .textSelection(.enabled)
        } else {
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(BreezyTheme.textPrimary)
                .textSelection(.enabled)
        }
    }

    private func htmlAttributedString(from html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
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
