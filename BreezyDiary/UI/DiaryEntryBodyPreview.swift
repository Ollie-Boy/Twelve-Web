import Foundation

enum DiaryEntryBodyPreview {
    /// Plain-text preview for list cards: strips common Markdown/HTML noise so `lineLimit` looks reasonable.
    static func plainText(for body: String, maxCharacters: Int = 220) -> String {
        var t = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "" }

        if let r = try? NSRegularExpression(pattern: #"```[\s\S]*?```"#, options: []) {
            t = r.stringByReplacingMatches(in: t, options: [], range: NSRange(t.startIndex..., in: t), withTemplate: " ")
        }
        t = t.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"__([^_]+)__"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^#{1,6}\s+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= maxCharacters { return t }
        let idx = t.index(t.startIndex, offsetBy: maxCharacters)
        return String(t[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
