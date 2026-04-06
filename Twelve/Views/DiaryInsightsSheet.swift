import SwiftUI

struct DiaryInsightsSheet: View {
    let entries: [DiaryEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var monthAnchor: Date = Date()

    private var summary: DiaryInsightsEngine.MonthSummary {
        DiaryInsightsEngine.monthSummary(entries: entries, forMonthContaining: monthAnchor)
    }

    private var monthTitle: String {
        monthAnchor.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button {
                            shiftMonth(-1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(TwelveTheme.appFont(size: 16))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text(monthTitle)
                            .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        Spacer()
                        Button {
                            shiftMonth(1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(TwelveTheme.appFont(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(TwelveTheme.textPrimary)
                    .padding(.horizontal, 4)

                    Text("\(summary.totalEntriesInMonth) entries this month")
                        .font(TwelveTheme.appFont(size: 13))
                        .foregroundStyle(TwelveTheme.textSecondary)

                    if summary.weatherCounts.isEmpty && summary.emotionCounts.isEmpty {
                        Text("No weather or emotion tags in this month.")
                            .font(TwelveTheme.appFont(size: 14))
                            .foregroundStyle(TwelveTheme.textTertiary)
                    } else {
                        if !summary.weatherCounts.isEmpty {
                            sectionTitle("Weather")
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(summary.weatherCounts, id: \.weather.id) { row in
                                    HStack {
                                        Label(row.weather.title, systemImage: row.weather.symbolName)
                                            .font(TwelveTheme.appFont(size: 15))
                                        Spacer()
                                        Text("\(row.count)")
                                            .font(TwelveTheme.appFont(size: 15))
                                            .foregroundStyle(TwelveTheme.textSecondary)
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        if !summary.emotionCounts.isEmpty {
                            sectionTitle("Mood / emotion")
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(summary.emotionCounts.enumerated()), id: \.offset) { _, row in
                                    HStack {
                                        Text(row.label)
                                            .font(TwelveTheme.appFont(size: 15))
                                        Spacer()
                                        Text("\(row.count)")
                                            .font(TwelveTheme.appFont(size: 15))
                                            .foregroundStyle(TwelveTheme.textSecondary)
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mood & weather")
                        .font(TwelveTheme.Settings.navigationTitle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.Settings.navigationDone)
                }
            }
        }
        .font(TwelveTheme.Settings.rootBody)
        .presentationDetents([.medium, .large])
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(TwelveTheme.appFont(size: 13, weight: .semibold))
            .foregroundStyle(TwelveTheme.textSecondary)
    }

    private func shiftMonth(_ delta: Int) {
        let cal = Calendar.current
        if let d = cal.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = d
        }
    }
}
