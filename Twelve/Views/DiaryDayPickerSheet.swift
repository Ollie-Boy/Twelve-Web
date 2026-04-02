import SwiftUI

/// Pick a calendar day and jump to entries on that day (newest first).
struct DiaryDayPickerSheet: View {
    let entries: [DiaryEntry]
    var onSelectEntry: (DiaryEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonthStart: Date = Self.initialMonthAnchor()

    private var calendar: Calendar { Calendar.current }

    private var entryCountOnSelectedDay: Int {
        entries(on: selectedDay).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CartoonMonthCalendar(
                        selectedDay: $selectedDay,
                        displayedMonthStart: $displayedMonthStart,
                        entryDates: entryDatesByStartOfDay
                    )

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
            .onAppear {
                let start = calendar.startOfDay(for: selectedDay)
                selectedDay = start
                displayedMonthStart = startOfMonth(containing: start)
            }
        }
        .presentationDetents([.large])
        .font(TwelveTheme.appFont(size: 16))
    }

    private static func initialMonthAnchor() -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let c = cal.dateComponents([.year, .month], from: today)
        return cal.date(from: c) ?? today
    }

    private var entryDatesByStartOfDay: Set<Date> {
        Set(entries.map { calendar.startOfDay(for: $0.selectedDate) })
    }

    private func startOfMonth(containing date: Date) -> Date {
        let c = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: c) ?? date
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

// MARK: - Cartoon month grid (explicit weeks — avoids LazyVGrid multi-ForEach misalignment)

private struct CartoonMonthCalendar: View {
    @Binding var selectedDay: Date
    @Binding var displayedMonthStart: Date
    let entryDates: Set<Date>

    private var calendar: Calendar { Calendar.current }

    private var orderedShortWeekdays: [String] {
        let syms = calendar.shortWeekdaySymbols
        guard syms.count == 7 else { return syms }
        let start = (calendar.firstWeekday - 1) % 7
        return (0..<7).map { syms[(start + $0) % 7] }
    }

    /// Each inner array is one week: `nil` = empty cell, `1...31` = day of month.
    private var weekRows: [[Int?]] {
        let first = firstOfDisplayedMonth
        guard let dayRange = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let days = Array(dayRange)
        let weekday = calendar.component(.weekday, from: first)
        let firstWeekday = calendar.firstWeekday
        let leading = (weekday - firstWeekday + 7) % 7

        var cells: [Int?] = Array(repeating: nil, count: leading) + days.map { Optional($0) }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return stride(from: 0, to: cells.count, by: 7).map { i in
            Array(cells[i..<min(i + 7, cells.count)])
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            monthHeader

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(Array(orderedShortWeekdays.enumerated()), id: \.offset) { _, sym in
                        Text(sym.uppercased())
                            .font(TwelveTheme.appFont(size: 11, weight: .bold))
                            .foregroundStyle(TwelveTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(Array(weekRows.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { col in
                            let day = col < week.count ? week[col] : nil
                            if let d = day {
                                dayCell(day: d)
                            } else {
                                Color.clear
                                    .frame(height: 44)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .cartoonPanelChrome()
    }

    private var monthHeader: some View {
        HStack(spacing: 12) {
            monthNavButton(delta: -1, label: "‹")

            Text(firstOfDisplayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(TwelveTheme.handwrittenFont(size: 26))
                .foregroundStyle(TwelveTheme.textPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            monthNavButton(delta: 1, label: "›")
        }
    }

    private func monthNavButton(delta: Int, label: String) -> some View {
        Button {
            shiftMonth(by: delta)
        } label: {
            Text(label)
                .font(TwelveTheme.handwrittenFont(size: 28))
                .foregroundStyle(TwelveTheme.primaryBlue)
                .frame(width: 44, height: 44)
                .background(TwelveTheme.softBlue.opacity(0.65), in: Circle())
                .overlay(Circle().stroke(TwelveTheme.primaryBlue.opacity(0.2), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var firstOfDisplayedMonth: Date {
        let c = calendar.dateComponents([.year, .month], from: displayedMonthStart)
        return calendar.date(from: c) ?? displayedMonthStart
    }

    private func shiftMonth(by delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: firstOfDisplayedMonth) else { return }
        displayedMonthStart = next
    }

    private func dateForDay(_ day: Int) -> Date {
        calendar.date(byAdding: .day, value: day - 1, to: firstOfDisplayedMonth) ?? firstOfDisplayedMonth
    }

    @ViewBuilder
    private func dayCell(day: Int) -> some View {
        let date = calendar.startOfDay(for: dateForDay(day))
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDay)
        let hasEntries = entryDates.contains(date)
        let isToday = calendar.isDateInToday(date)

        Button {
            selectedDay = date
        } label: {
            ZStack(alignment: .bottom) {
                Text("\(day)")
                    .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : TwelveTheme.textPrimary)

                if hasEntries && !isSelected {
                    Circle()
                        .fill(TwelveTheme.primaryBlue)
                        .frame(width: 5, height: 5)
                        .offset(y: 2)
                } else if hasEntries && isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 4, height: 4)
                        .offset(y: 2)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [TwelveTheme.primaryBlue, TwelveTheme.primaryBlueDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else if hasEntries {
                        Circle()
                            .fill(TwelveTheme.softBlue.opacity(0.45))
                    } else {
                        Circle()
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                Circle()
                    .stroke(
                        isToday ? TwelveTheme.accentYellow : Color.clear,
                        lineWidth: isToday ? 2.5 : 0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
