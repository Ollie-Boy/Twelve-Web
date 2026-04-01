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
    @State private var selectedMediaURL: URL?

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
            .sheet(item: $selectedMediaURL) { url in
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
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
                    Button {
                        openAttachment(item)
                    } label: {
                        HStack {
                            Image(systemName: item.kind.iconName)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayName)
                                Text(item.kind.title)
                                    .font(.system(size: 11))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BreezyTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
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
            if let image = UIImage(contentsOfFile: item.url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        case .video:
            InlineAVPlayerView(url: item.url, height: 220)
        case .audio:
            InlineAVPlayerView(url: item.url, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        default:
            EmptyView()
        }
    }

    private func openAttachment(_ item: DiaryAttachment) {
        switch item.kind {
        case .video:
            selectedMediaURL = item.url
        case .audio:
            selectedMediaURL = item.url
        case .image, .gif:
            quickLookURL = item.url
        default:
            quickLookURL = item.url
        }
    }
}

private struct InlineAVPlayerView: View {
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
