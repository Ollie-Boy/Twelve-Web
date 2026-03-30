import QuickLook
import SwiftUI

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct DiaryReaderSheet: View {
    let entry: DiaryEntry
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var quickLookURL: URL?

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
        }
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attachments")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BreezyTheme.textPrimary)
            ForEach(entry.attachments) { item in
                Button {
                    quickLookURL = item.url
                } label: {
                    HStack {
                        Image(systemName: item.kind.iconName)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                            Text(item.kind.title)
                                .font(.system(size: 11))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BreezyTheme.textPrimary)
                    .padding(12)
                    .background(BreezyTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BreezyTheme.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
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
