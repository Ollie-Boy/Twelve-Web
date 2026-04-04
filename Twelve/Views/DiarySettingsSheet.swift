import LinkPresentation
import SwiftUI
import UIKit

struct DiarySettingsSheet: View {
    let entries: [DiaryEntry]
    var onEntriesChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var promptsOn = DiaryWritingPromptStore.isEnabled
    @State private var exportPayload: ExportPayload?
    @State private var showCleanupConfirm = false
    @State private var cleanupMessage: String?

    struct ExportPayload: Identifiable {
        let id = UUID()
        let text: String
        let filename: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("iCloud backup (optional)")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Toggle("Mirror diary JSON to iCloud", isOn: Binding(
                            get: { ICloudDataMirror.twelveEnabled },
                            set: { v in
                                ICloudDataMirror.twelveEnabled = v
                                if v, let data = try? JSONEncoder().encode(entries) {
                                    ICloudDataMirror.mirrorTwelveDiaryJSON(data)
                                }
                            }
                        ))
                        .tint(TwelveTheme.primaryBlue)
                        Text(ICloudDataMirror.twelveMirrorStatusLine())
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Writing")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Toggle(isOn: $promptsOn) {
                            Text("Daily writing prompt")
                                .font(TwelveTheme.appFont(size: 16, weight: .medium))
                        }
                        .tint(TwelveTheme.primaryBlue)
                        .onChange(of: promptsOn) { _, v in
                            DiaryWritingPromptStore.isEnabled = v
                        }
                        Text("Shows a gentle idea when you start a new entry.")
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Export")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Button {
                            let md = DiaryExportService.exportMarkdown(entries: entries)
                            exportPayload = ExportPayload(text: md, filename: DiaryExportService.exportFilename())
                        } label: {
                            Label("Export all entries as Markdown", systemImage: "square.and.arrow.up")
                                .font(TwelveTheme.appFont(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(TwelveTheme.textPrimary)
                        Text("Attachments are not embedded; only text and metadata.")
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Storage")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Text("Attachments use about \(DiaryAttachmentCleanup.humanReadableSize(DiaryAttachmentCleanup.attachmentDirectoryByteSize())).")
                            .font(TwelveTheme.appFont(size: 14))
                            .foregroundStyle(TwelveTheme.textPrimary)
                        Button(role: .destructive) {
                            showCleanupConfirm = true
                        } label: {
                            Text("Remove orphaned attachment files")
                                .font(TwelveTheme.appFont(size: 16, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        Text("Deletes files on disk that no diary entry references.")
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TwelveTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Diary settings")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.appFont(size: 17))
                }
            }
        }
        .font(TwelveTheme.appFont(size: 16))
        .presentationDetents([.medium, .large])
        .sheet(item: $exportPayload) { payload in
            ActivityView(activityItems: [ExportItemSource(text: payload.text, filename: payload.filename)])
        }
        .alert("Remove orphaned files?", isPresented: $showCleanupConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { runCleanup() }
        } message: {
            Text("This only removes files not linked from any entry.")
        }
        .alert("Cleanup", isPresented: Binding(get: { cleanupMessage != nil }, set: { if !$0 { cleanupMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cleanupMessage ?? "")
        }
    }

    private func runCleanup() {
        do {
            let orphans = try DiaryAttachmentCleanup.orphanURLs(entries: entries)
            var removed = 0
            for url in orphans {
                try? FileManager.default.removeItem(at: url)
                removed += 1
            }
            cleanupMessage = removed == 0 ? "No orphaned files found." : "Removed \(removed) file(s)."
        } catch {
            cleanupMessage = "Could not scan attachments."
        }
        onEntriesChanged()
    }
}

// MARK: - Share markdown as file

private final class ExportItemSource: NSObject, UIActivityItemSource {
    private let text: String
    private let filename: String

    init(text: String, filename: String) {
        self.text = text
        self.filename = filename
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        "public.plain-text"
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        filename
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let meta = LPLinkMetadata()
        meta.title = filename
        return meta
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
