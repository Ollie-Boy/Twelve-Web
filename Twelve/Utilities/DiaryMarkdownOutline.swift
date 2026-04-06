import Foundation

/// Extracts ATX Markdown headings (# …) from plain text for an outline (reader navigation).
enum DiaryMarkdownOutline {
    /// True when body is not treated as raw HTML in the reader (markdown / plain path gets heading ids in WebView).
    static func showsOutline(for body: String) -> Bool {
        let t = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 6 else { return true }
        let lower = t.lowercased()
        if lower.hasPrefix("<!doctype") || lower.hasPrefix("<html") { return false }
        let pattern = #"<[\s/]?(p|div|span|br|h[1-6]|ul|ol|li|strong|b|em|i|a|table|tr|td|th|blockquote|pre|code|section|article|header|footer|nav)\b"#
        return t.range(of: pattern, options: .regularExpression) == nil
    }

    struct Item: Identifiable {
        let id: Int
        let level: Int
        let title: String
    }

    private static let lineRegex = try! NSRegularExpression(
        pattern: "^(#{1,4})\\s+(.+?)\\s*$",
        options: [.anchorsMatchLines]
    )

    static func headings(from markdown: String) -> [Item] {
        let ns = markdown as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = lineRegex.matches(in: markdown, options: [], range: range)
        var out: [Item] = []
        var idx = 0
        for m in matches {
            guard m.numberOfRanges >= 3,
                  let r1 = Range(m.range(at: 1), in: markdown),
                  let r2 = Range(m.range(at: 2), in: markdown)
            else { continue }
            let hashes = String(markdown[r1])
            let title = String(markdown[r2]).trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            let level = hashes.count
            out.append(Item(id: idx, level: level, title: title))
            idx += 1
        }
        return out
    }
}
