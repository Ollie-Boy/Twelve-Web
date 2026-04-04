import SwiftUI

struct DiarySearchSheet: View {
    let entries: [DiaryEntry]
    var onPick: (DiaryEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [DiaryEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return entries.filter { e in
            if e.title.lowercased().contains(q) { return true }
            if e.body.lowercased().contains(q) { return true }
            if e.tags.contains(where: { $0.lowercased().contains(q) }) { return true }
            if let em = e.emotion?.lowercased(), em.contains(q) { return true }
            return false
        }
        .sorted { $0.selectedDate > $1.selectedDate }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(TwelveTheme.textTertiary)
                    TextField("Title, body, tag…", text: $query)
                        .textFieldStyle(.plain)
                        .font(TwelveTheme.appFont(size: 16))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Type to search your diary.")
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
