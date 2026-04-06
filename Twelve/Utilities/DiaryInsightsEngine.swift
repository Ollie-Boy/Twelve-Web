import Foundation

/// Aggregates weather and free-text emotion for diary entries in a calendar month (by `selectedDate`).
enum DiaryInsightsEngine {
    struct MonthSummary {
        let year: Int
        let month: Int
        let weatherCounts: [(weather: WeatherOption, count: Int)]
        let emotionCounts: [(label: String, count: Int)]
        let totalEntriesInMonth: Int
    }

    static func monthSummary(entries: [DiaryEntry], forMonthContaining date: Date) -> MonthSummary {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)

        var inMonth: [DiaryEntry] = []
        for e in entries {
            let ey = cal.component(.year, from: e.selectedDate)
            let em = cal.component(.month, from: e.selectedDate)
            guard ey == y, em == m else { continue }
            inMonth.append(e)
        }

        var weatherMap: [WeatherOption: Int] = [:]
        var emotionMap: [String: Int] = [:]

        for e in inMonth {
            if e.weather != .none {
                weatherMap[e.weather, default: 0] += 1
            }
            if let emo = e.emotion?.trimmingCharacters(in: .whitespacesAndNewlines), !emo.isEmpty {
                emotionMap[emo, default: 0] += 1
            }
        }

        let weatherCounts = weatherMap.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
        let emotionCounts = emotionMap.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }

        return MonthSummary(
            year: y,
            month: m,
            weatherCounts: weatherCounts,
            emotionCounts: emotionCounts,
            totalEntriesInMonth: inMonth.count
        )
    }
}
