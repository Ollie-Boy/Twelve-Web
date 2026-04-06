import Foundation

enum DiaryWritingStreak {
    /// Calendar days (start of day) that have at least one entry (by selectedDate).
    static func daysWithEntries(entries: [DiaryEntry]) -> Set<Date> {
        let cal = Calendar.current
        var set = Set<Date>()
        for e in entries {
            let d = cal.startOfDay(for: e.selectedDate)
            set.insert(d)
        }
        return set
    }

    /// Consecutive calendar days ending today, or ending yesterday if today is empty (common streak grace).
    static func currentStreak(entries: [DiaryEntry]) -> Int {
        let cal = Calendar.current
        let days = daysWithEntries(entries: entries)
        guard let anchor = streakAnchorDay(days: days, cal: cal) else { return 0 }
        var cursor = anchor
        var n = 0
        while days.contains(cursor) {
            n += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = cal.startOfDay(for: prev)
        }
        return n
    }

    private static func streakAnchorDay(days: Set<Date>, cal: Calendar) -> Date? {
        let today = cal.startOfDay(for: Date())
        if days.contains(today) { return today }
        if let y = cal.date(byAdding: .day, value: -1, to: today) {
            let ys = cal.startOfDay(for: y)
            if days.contains(ys) { return ys }
        }
        return nil
    }

    /// Entries written Mon–Sun of this week (selectedDate).
    static func entriesThisWeekCount(entries: [DiaryEntry]) -> Int {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)
        else { return 0 }
        return entries.filter { e in
            e.selectedDate >= weekStart && e.selectedDate < weekEnd
        }.count
    }

    /// 12 columns × 7 rows: each column is one week (oldest left); rows are days in week order from `weekStart`.
    static func last12WeeksGrid(entries: [DiaryEntry]) -> [[Bool]] {
        let cal = Calendar.current
        let days = daysWithEntries(entries: entries)
        var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 7), count: 12)
        guard let interval = cal.dateInterval(of: .weekOfYear, for: Date()) else { return grid }
        let thisWeekStart = cal.startOfDay(for: interval.start)
        guard let oldestWeekStart = cal.date(byAdding: .weekOfYear, value: -11, to: thisWeekStart) else { return grid }
        for col in 0..<12 {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: col, to: oldestWeekStart) else { continue }
            let ws = cal.startOfDay(for: weekStart)
            for row in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: row, to: ws) else { continue }
                if days.contains(cal.startOfDay(for: day)) { grid[col][row] = true }
            }
        }
        return grid
    }
}
