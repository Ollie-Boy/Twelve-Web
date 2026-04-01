import QuickLook
import SwiftUI
import AVKit
import UIKit

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct DiaryReaderSheet: View {
    let entry: DiaryEntry
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var quickLookURL: URL?
    @State private var selectedImageURL: URL?

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
                    .foregroundStyle(.black)

                    Text(entry.selectedDate.formatted(date: .complete, time: .shortened))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(BreezyTheme.textSecondary)

                    if !entry.body.isEmpty {
                        MarkdownOrPlainTextView(text: entry.body)
                    }

                    if !entry.attachments.isEmpty {
                        attachmentSection
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
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attachments")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BreezyTheme.textPrimary)
            ForEach(entry.attachments) { item in
                VStack(alignment: .leading, spacing: 10) {
                    mediaPreview(for: item)
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

    @ViewBuilder
    private func mediaPreview(for item: DiaryAttachment) -> some View {
        switch item.kind {
        case .image, .gif:
            Button {
                selectedImageURL = item.url
            } label: {
                if let image = UIImage(contentsOfFile: item.url.path) {
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

    var body: some View {
        if text.contains("$") || text.contains("\\(") || text.contains("\\[") {
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
        } else if let attributed = try? AttributedString(markdown: text) {
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
