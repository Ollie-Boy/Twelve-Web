import Foundation

enum DiaryOnThisDay {
    /// Entries on the same calendar month-day in a **past** year (not today’s year).
    static func pastYearEntries(matching reference: Date = Date(), in entries: [DiaryEntry]) -> [DiaryEntry] {
        let cal = Calendar.current
        let m = cal.component(.month, from: reference)
        let d = cal.component(.day, from: reference)
        let y = cal.component(.year, from: reference)
        return entries.filter { e in
            let em = cal.component(.month, from: e.selectedDate)
            let ed = cal.component(.day, from: e.selectedDate)
            let ey = cal.component(.year, from: e.selectedDate)
            return em == m && ed == d && ey < y
        }
        .sorted { $0.selectedDate > $1.selectedDate }
    }
}
