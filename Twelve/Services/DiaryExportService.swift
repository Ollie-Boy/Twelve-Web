import Foundation

enum DiaryExportService {
    /// Markdown text for all entries (newest first).
    static func exportMarkdown(entries: [DiaryEntry]) -> String {
        let sorted = entries.sorted { $0.selectedDate > $1.selectedDate }
        var lines: [String] = ["# Twelve export", "", "Generated: \(ISO8601DateFormatter().string(from: Date()))", ""]
        for e in sorted {
            lines.append("---")
            lines.append("")
            lines.append("## \(e.title.isEmpty ? "Untitled" : e.title)")
            lines.append("")
            lines.append("- **Date:** \(e.selectedDate.formatted(date: .complete, time: .shortened))")
            if e.weather != .none {
                lines.append("- **Weather:** \(e.weather.title)")
            }
            if let loc = e.location, !loc.isEmpty {
                lines.append("- **Location:** \(loc)")
            }
            if !e.tags.isEmpty {
                lines.append("- **Tags:** \(e.tags.map { "#\($0)" }.joined(separator: " "))")
            }
            if let em = e.emotion?.trimmingCharacters(in: .whitespacesAndNewlines), !em.isEmpty {
                lines.append("- **Emotion:** \(em)")
            }
            lines.append("")
            lines.append(e.body)
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    static func exportFilename() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "Twelve-export-\(f.string(from: Date())).md"
    }
}
