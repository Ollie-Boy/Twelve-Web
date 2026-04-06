import SwiftUI

struct DiarySearchSheet: View {
    let entries: [DiaryEntry]
    var onPick: (DiaryEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var tagFilter = ""
    @State private var attachmentFilter: AttachmentFilter = .all
    @State private var useFromDate = false
    @State private var useToDate = false
    @State private var fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDate = Date()

    enum AttachmentFilter: String, CaseIterable, Identifiable {
        case all
        case withAttachments
        case withoutAttachments
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: return "Any"
            case .withAttachments: return "With attachments"
            case .withoutAttachments: return "Text only"
            }
        }
    }

    private var filtered: [DiaryEntry] {
        let cal = Calendar.current
        var list = entries
        if useFromDate {
            let start = cal.startOfDay(for: fromDate)
            list = list.filter { $0.selectedDate >= start }
        }
        if useToDate {
            var c = cal.dateComponents([.year, .month, .day], from: toDate)
            c.hour = 23
            c.minute = 59
            c.second = 59
            if let end = cal.date(from: c) {
                list = list.filter { $0.selectedDate <= end }
            }
        }
        switch attachmentFilter {
        case .all: break
        case .withAttachments: list = list.filter { !$0.attachments.isEmpty }
        case .withoutAttachments: list = list.filter { $0.attachments.isEmpty }
        }
        let tagT = tagFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tagT.isEmpty {
            list = list.filter { e in
                e.tags.contains { $0.localizedCaseInsensitiveCompare(tagT) == .orderedSame }
            }
        }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { e in
                if e.title.lowercased().contains(q) { return true }
                if e.body.lowercased().contains(q) { return true }
                if e.tags.contains(where: { $0.lowercased().contains(q) }) { return true }
                if let em = e.emotion?.lowercased(), em.contains(q) { return true }
                return false
            }
        }
        return list.sorted { $0.selectedDate > $1.selectedDate }
    }

    private var hasAnyFilter: Bool {
        useFromDate || useToDate || attachmentFilter != .all || !tagFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSearch: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasAnyFilter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(TwelveTheme.toolbarIconFont(size: 18))
                        .foregroundStyle(TwelveTheme.textTertiary)
                    TextField("Title, body, tag…", text: $query)
                        .textFieldStyle(.plain)
                        .font(TwelveTheme.appFont(size: 16))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Filters")
                        .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textSecondary)
                    TextField("Exact tag match", text: $tagFilter)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Picker("Attachments", selection: $attachmentFilter) {
                        ForEach(AttachmentFilter.allCases) { f in
                            Text(f.title).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("From date", isOn: $useFromDate)
                    if useFromDate {
                        DatePicker("", selection: $fromDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Toggle("To date", isOn: $useToDate)
                    if useToDate {
                        DatePicker("", selection: $toDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding(12)
                .background(TwelveTheme.secondarySurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !canSearch {
                    Text("Type keywords or turn on a filter.")
                        .font(TwelveTheme.appFont(size: 14))
                        .foregroundStyle(TwelveTheme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if filtered.isEmpty {
                    Text("No matches.")
                        .font(TwelveTheme.appFont(size: 14))
                        .foregroundStyle(TwelveTheme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(filtered) { e in
                                Button {
                                    onPick(e)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(e.title.isEmpty ? "Untitled" : e.title)
                                            .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                                            .foregroundStyle(TwelveTheme.textPrimary)
                                        Text(e.selectedDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(TwelveTheme.appFont(size: 12))
                                            .foregroundStyle(TwelveTheme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(TwelveTheme.hairline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Search")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.appFont(size: 17))
                }
            }
        }
        .font(TwelveTheme.appFont(size: 16))
    }
}
