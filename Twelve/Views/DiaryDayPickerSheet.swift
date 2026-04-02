import SwiftUI

/// Pick a calendar day and jump to entries on that day (newest first).
struct DiaryDayPickerSheet: View {
    let entries: [DiaryEntry]
    var onSelectEntry: (DiaryEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private var calendar: Calendar { Calendar.current }

    private var entryCountOnSelectedDay: Int {
        entries(on: selectedDay).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DatePicker(
                        "",
                        selection: $selectedDay,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(TwelveTheme.primaryBlueDark.opacity(0.85))
                    .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedDay.formatted(date: .complete, time: .omitted))
                            .font(TwelveTheme.appFont(size: 15, weight: .semibold))
                            .foregroundStyle(TwelveTheme.textPrimary)

                        if entryCountOnSelectedDay == 0 {
                            Text("No entries on this day.")
                                .font(TwelveTheme.appFont(size: 15))
                                .foregroundStyle(TwelveTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Text("\(entryCountOnSelectedDay) entr\(entryCountOnSelectedDay == 1 ? "y" : "ies")")
                                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                                .foregroundStyle(TwelveTheme.textSecondary)

                            VStack(spacing: 10) {
                                ForEach(entries(on: selectedDay)) { entry in
                                    Button {
                                        dismiss()
                                        DispatchQueue.main.async {
                                            onSelectEntry(entry)
                                        }
                                    } label: {
                                        dayEntryRow(entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(TwelveTheme.background)
            .navigationTitle("Jump to day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.appFont(size: 17))
                }
            }
        }
        .presentationDetents([.large])
        .font(TwelveTheme.appFont(size: 16))
    }

    private func entries(on day: Date) -> [DiaryEntry] {
        let start = calendar.startOfDay(for: day)
        return entries
            .filter { calendar.startOfDay(for: $0.selectedDate) == start }
            .sorted { $0.selectedDate > $1.selectedDate }
    }

    private func dayEntryRow(_ entry: DiaryEntry) -> some View {
        let title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = title.isEmpty ? "Untitled Day" : title
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(entry.selectedDate.formatted(date: .omitted, time: .shortened))
                    .font(TwelveTheme.appFont(size: 13))
                    .foregroundStyle(TwelveTheme.textSecondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                .foregroundStyle(TwelveTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TwelveTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TwelveTheme.hairline, lineWidth: 1)
        )
    }
}
