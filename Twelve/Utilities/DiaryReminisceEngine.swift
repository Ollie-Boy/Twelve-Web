import Foundation

enum DiaryReminisceEngine {
    /// Pick a random entry from at least `minDaysAgo` days ago (by selectedDate).
    static func randomPastEntry(entries: [DiaryEntry], minDaysAgo: Int = 7) -> DiaryEntry? {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -minDaysAgo, to: Date()) else { return nil }
        let pool = entries.filter { $0.selectedDate < cutoff }
        return pool.randomElement()
    }

    static func excerpt(from body: String, maxLen: Int = 160) -> String {
        let t = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "No text in this entry." }
        let line = t.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init) ?? t
        if line.count <= maxLen { return line }
        let idx = line.index(line.startIndex, offsetBy: maxLen)
        return String(line[..<idx]).trimmingCharacters(in: .whitespaces) + "…"
    }
}
