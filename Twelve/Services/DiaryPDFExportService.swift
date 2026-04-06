import Foundation
import UIKit

enum DiaryPDFExportService {
    private static let pageW: CGFloat = 612
    private static let pageH: CGFloat = 792
    private static let margin: CGFloat = 56

    static func exportPDF(entries: [DiaryEntry]) throws -> URL {
        let sorted = entries.sorted { $0.selectedDate > $1.selectedDate }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(pdfFilename())
        let metaFont = TwelveTheme.uiFontForApp(size: 11)
        let titleFont = TwelveTheme.uiFontForApp(size: 20, weight: .semibold)
        let bodyFont = TwelveTheme.uiFontForApp(size: 13)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        try renderer.writePDF(to: url) { ctx in
            var y = margin
            func newPage() {
                ctx.beginPage()
                y = margin
            }
            newPage()

            drawLine("Twelve — export", font: titleFont, color: .label, y: &y, newPage: newPage)
            y += 4
            drawLine("Generated \(Date().formatted(date: .abbreviated, time: .shortened))", font: metaFont, color: .secondaryLabel, y: &y, newPage: newPage)
            y += 18

            for e in sorted {
                let t = e.title.isEmpty ? "Untitled" : e.title
                drawLine(t, font: titleFont, color: .label, y: &y, newPage: newPage)
                y += 4

                var meta: [String] = []
                meta.append(e.selectedDate.formatted(date: .complete, time: .shortened))
                if e.weather != .none { meta.append(e.weather.title) }
                if let loc = e.location, !loc.isEmpty { meta.append(loc) }
                if !e.tags.isEmpty { meta.append(e.tags.map { "#\($0)" }.joined(separator: " ")) }
                if let em = e.emotion?.trimmingCharacters(in: .whitespacesAndNewlines), !em.isEmpty { meta.append(em) }
                drawParagraph(meta.joined(separator: " · "), font: metaFont, color: .secondaryLabel, y: &y, newPage: newPage)
                y += 8

                let body = e.body.isEmpty ? "(No body)" : e.body
                drawParagraph(body, font: bodyFont, color: .label, y: &y, newPage: newPage)
                y += 12
                drawLine("— — —", font: metaFont, color: .tertiaryLabel, y: &y, newPage: newPage)
                y += 10
            }
        }
        return url
    }

    static func pdfFilename() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "Twelve-export-\(f.string(from: Date())).pdf"
    }

    private static func drawLine(_ text: String, font: UIFont, color: UIColor, y: inout CGFloat, newPage: () -> Void) {
        let h = font.lineHeight
        if y + h > pageH - margin { newPage() }
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        (text as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
        y += h
    }

    /// Multi-line paragraph; paginates when rect would exceed page.
    private static func drawParagraph(_ text: String, font: UIFont, color: UIColor, y: inout CGFloat, newPage: () -> Void) {
        let w = pageW - 2 * margin
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let paragraphs = text.components(separatedBy: "\n")
        for para in paragraphs {
            var remaining = para
            while !remaining.isEmpty {
                let maxH = pageH - margin - y
                if maxH < font.lineHeight {
                    newPage()
                    continue
                }
                let chunk = chunkFitting(remaining, width: w, maxHeight: maxH, attributes: attrs)
                if chunk.isEmpty {
                    newPage()
                    continue
                }
                let h = (chunk as NSString).boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil).height
                let drawH = ceil(h)
                (chunk as NSString).draw(with: CGRect(x: margin, y: y, width: w, height: drawH), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
                y += drawH + 2
                if chunk.count < remaining.count {
                    remaining = String(remaining.dropFirst(chunk.count)).trimmingCharacters(in: .whitespaces)
                } else {
                    remaining = ""
                }
            }
            y += 4
        }
    }

    private static func chunkFitting(_ text: String, width: CGFloat, maxHeight: CGFloat, attributes: [NSAttributedString.Key: Any]) -> String {
        let ns = text as NSString
        let len = ns.length
        if len == 0 { return "" }
        var low = 1
        var high = len
        var best = 0
        while low <= high {
            let mid = (low + high) / 2
            let sub = ns.substring(with: NSRange(location: 0, length: mid))
            let h = (sub as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil).height
            if h <= maxHeight {
                best = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        if best == 0 {
            return ns.substring(with: NSRange(location: 0, length: 1))
        }
        var s = ns.substring(with: NSRange(location: 0, length: best))
        if best < len, let idx = s.lastIndex(of: " ") {
            s = String(s[..<idx])
        }
        if s.isEmpty {
            s = ns.substring(with: NSRange(location: 0, length: best))
        }
        return s
    }
}
