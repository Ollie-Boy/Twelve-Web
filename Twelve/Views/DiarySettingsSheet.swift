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
    @State private var fontScale: AppFontScale = AppFontScale.current
    @State private var reminderOn = DiaryReminderStore.isEnabled
    @State private var reminderHour = DiaryReminderStore.hour
    @State private var reminderMinute = DiaryReminderStore.minute
    @State private var pdfURL: URL?
    @State private var pdfError: String?

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
                        Text("Text size")
                            .font(TwelveTheme.Settings.sectionHeader)
                            .foregroundStyle(TwelveTheme.textSecondary)
                        SettingsFontScaleControl(fontScale: $fontScale)
                            .onChange(of: fontScale) { _, v in
                                AppFontScale.setCurrent(v)
                                NotificationCenter.default.post(name: .appFontScaleDidChange, object: nil)
                            }
                        Text("Applies after a moment across the diary UI.")
                            .font(TwelveTheme.Settings.caption)
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily reminder")
                            .font(TwelveTheme.Settings.sectionHeader)
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Toggle(isOn: $reminderOn) {
                            Text("Gentle nudge to write")
                                .font(TwelveTheme.Settings.rowPrimary)
                        }
                        .tint(TwelveTheme.primaryBlue)
                        .onChange(of: reminderOn) { _, v in
                            DiaryReminderStore.isEnabled = v
                            if v {
                                Task { await DiaryReminderStore.schedule() }
                            }
                        }
                        if reminderOn {
                            SettingsReminderTimeWheel(hour: $reminderHour, minute: $reminderMinute)
                                .onChange(of: reminderHour) { _, _ in
                                    DiaryReminderStore.hour = reminderHour
                                    DiaryReminderStore.minute = reminderMinute
                                    Task { await DiaryReminderStore.schedule() }
                                }
                                .onChange(of: reminderMinute) { _, _ in
                                    DiaryReminderStore.hour = reminderHour
                                    DiaryReminderStore.minute = reminderMinute
                                    Task { await DiaryReminderStore.schedule() }
                                }
                        }
                        Text("When you turn this on, iOS may ask to allow notifications. If you chose Don’t Allow earlier, open Settings → Twelve → Notifications and turn on Allow Notifications so reminders can appear.")
                            .font(TwelveTheme.Settings.caption)
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("iCloud backup (optional)")
                            .font(TwelveTheme.Settings.sectionHeader)
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Toggle(isOn: Binding(
                            get: { ICloudDataMirror.twelveEnabled },
                            set: { v in
                                ICloudDataMirror.twelveEnabled = v
                                if v, let data = try? JSONEncoder().encode(entries) {
                                    ICloudDataMirror.mirrorTwelveDiaryJSON(data)
                                }
                            }
                        )) {
                            Text("Mirror diary JSON to iCloud")
                                .font(TwelveTheme.Settings.rowPrimary)
                        }
                        .tint(TwelveTheme.primaryBlue)
                        Text(ICloudDataMirror.twelveMirrorStatusLine())
                            .font(TwelveTheme.Settings.caption)
                            .foregroundStyle(TwelveTheme.textTertiary)
                        if let line = BackupStatusStore.twelveMirrorLine() {
                            Text(line)
                                .font(TwelveTheme.Settings.finePrint)
                                .foregroundStyle(TwelveTheme.textTertiary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Writing")
                            .font(TwelveTheme.Settings.sectionHeader)
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Toggle(isOn: $promptsOn) {
                            Text("Daily writing prompt")
                                .font(TwelveTheme.Settings.rowPrimary)
                        }
                        .tint(TwelveTheme.primaryBlue)
                        .onChange(of: promptsOn) { _, v in
                            DiaryWritingPromptStore.isEnabled = v
                        }
                        Text("Shows a gentle idea when you start a new entry.")
                            .font(TwelveTheme.Settings.caption)
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Export")
                            .font(TwelveTheme.Settings.sectionHeader)
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Button {
                            let md = DiaryExportService.exportMarkdown(entries: entries)
                            exportPayload = ExportPayload(text: md, filename: DiaryExportService.exportFilename())
                            BackupStatusStore.markTwelveExportSuccess()
                        } label: {
                            Label("Export all entries as Markdown", systemImage: "square.and.arrow.up")
                                .font(TwelveTheme.Settings.rowPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(TwelveTheme.textPrimary)
                        Button {
                            do {
                                pdfURL = try DiaryPDFExportService.exportPDF(entries: entries)
                                BackupStatusStore.markTwelveExportSuccess()
                            } catch {
                                pdfError = "Could not build PDF."
                            }
                        } label: {
                            Label("Export PDF for printing", systemImage: "doc.richtext")
                                .font(TwelveTheme.Settings.rowPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(TwelveTheme.textPrimary)
                        if let line = BackupStatusStore.twelveExportLine() {
                            Text(line)
                                .font(TwelveTheme.Settings.finePrint)
                                .foregroundStyle(TwelveTheme.textTertiary)
                        }
                        Text("Attachments are not embedded; only text and metadata.")
                            .font(TwelveTheme.Settings.caption)
                            .foregroundStyle(TwelveTheme.textTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Storage")
                            .font(TwelveTheme.Settings.sectionHeader)
                            .foregroundStyle(TwelveTheme.textSecondary)
                        Text("Attachments use about \(DiaryAttachmentCleanup.humanReadableSize(DiaryAttachmentCleanup.attachmentDirectoryByteSize())).")
                            .font(TwelveTheme.Settings.rowPrimary)
                            .foregroundStyle(TwelveTheme.textPrimary)
                        Button(role: .destructive) {
                            showCleanupConfirm = true
                        } label: {
                            Text("Remove orphaned attachment files")
                                .font(TwelveTheme.Settings.rowPrimary)
                        }
                        .buttonStyle(.plain)
                        Text("Deletes files on disk that no diary entry references.")
                            .font(TwelveTheme.Settings.caption)
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
                        .font(TwelveTheme.Settings.navigationTitle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.Settings.navigationDone)
                }
            }
            .onAppear {
                fontScale = AppFontScale.current
                reminderOn = DiaryReminderStore.isEnabled
                reminderHour = DiaryReminderStore.hour
                reminderMinute = DiaryReminderStore.minute
            }
        }
        .font(TwelveTheme.Settings.rootBody)
        .presentationDetents([.large])
        .sheet(item: $exportPayload) { payload in
            ActivityView(activityItems: [ExportItemSource(text: payload.text, filename: payload.filename)])
        }
        .sheet(item: Binding(
            get: { pdfURL.map { PDFShareItem(url: $0) } },
            set: { if $0 == nil { pdfURL = nil } }
        )) { item in
            ActivityView(activityItems: [item.url])
        }
        .alert("PDF", isPresented: Binding(get: { pdfError != nil }, set: { if !$0 { pdfError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pdfError ?? "")
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

private struct PDFShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
