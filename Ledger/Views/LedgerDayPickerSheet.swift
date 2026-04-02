import SwiftUI

/// Calendar + list of all ledger rows on the selected day (newest first).
struct LedgerDayPickerSheet: View {
    let entries: [LedgerEntry]
    var formatMoney: (Decimal) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonthStart: Date = Self.initialMonthAnchor()

    private var calendar: Calendar { Calendar.current }

    private var entryDatesByStartOfDay: Set<Date> {
        Set(entries.map { calendar.startOfDay(for: $0.date) })
    }

    private var countOnSelectedDay: Int {
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

                        if countOnSelectedDay == 0 {
                            Text("No transactions on this day.")
                                .font(TwelveTheme.appFont(size: 15))
                                .foregroundStyle(TwelveTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Text("\(countOnSelectedDay) item\(countOnSelectedDay == 1 ? "" : "s")")
                                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                                .foregroundStyle(TwelveTheme.textSecondary)

                            VStack(spacing: 10) {
                                ForEach(entries(on: selectedDay)) { entry in
                                    dayRow(entry)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TwelveTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Jump to day")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
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

    private func startOfMonth(containing date: Date) -> Date {
        let c = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: c) ?? date
    }

    private func entries(on day: Date) -> [LedgerEntry] {
        let start = calendar.startOfDay(for: day)
        return entries
            .filter { calendar.startOfDay(for: $0.date) == start }
            .sorted { $0.date > $1.date }
    }

    private func dayRow(_ entry: LedgerEntry) -> some View {
        let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let loc = entry.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.category)
                        .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                    if entry.refundTotal > 0 {
                        Text("Refund")
                            .font(TwelveTheme.appFont(size: 11, weight: .bold))
                            .foregroundStyle(TwelveTheme.primaryBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(TwelveTheme.softBlue.opacity(0.55), in: Capsule())
                    }
                }
                if !note.isEmpty {
                    Text(note)
                        .font(TwelveTheme.appFont(size: 13))
                        .foregroundStyle(TwelveTheme.textSecondary)
                        .lineLimit(2)
                }
                if !loc.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(TwelveTheme.appFont(size: 11))
                            .foregroundStyle(TwelveTheme.textTertiary)
                        Text(loc)
                            .font(TwelveTheme.appFont(size: 11))
                            .foregroundStyle(TwelveTheme.textTertiary)
                            .lineLimit(2)
                    }
                }
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(TwelveTheme.appFont(size: 12))
                    .foregroundStyle(TwelveTheme.textTertiary)
            }
            Spacer(minLength: 8)
            Text(amountLabel(entry))
                .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                .foregroundStyle(amountColor(entry))
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

    private func amountLabel(_ entry: LedgerEntry) -> String {
        switch entry.kind {
        case .expense:
            return "−\(formatMoney(entry.netAmount))"
        case .income:
            return "+\(formatMoney(entry.netAmount))"
        }
    }

    private func amountColor(_ entry: LedgerEntry) -> Color {
        switch entry.kind {
        case .expense:
            return TwelveTheme.primaryBlueDark
        case .income:
            return TwelveTheme.primaryBlue
        }
    }
}
