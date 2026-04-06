import Foundation

enum BackupStatusStore {
    private static let twelveExportKey = "twelve.lastExportSuccessAt"
    private static let twelveMirrorKey = "twelve.lastMirrorSuccessAt"
    private static let ledgerExportKey = "ledger.lastExportSuccessAt"
    private static let ledgerMirrorKey = "ledger.lastMirrorSuccessAt"

    static func markTwelveExportSuccess() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: twelveExportKey)
    }

    static func markTwelveMirrorSuccess() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: twelveMirrorKey)
    }

    static func markLedgerExportSuccess() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: ledgerExportKey)
    }

    static func markLedgerMirrorSuccess() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: ledgerMirrorKey)
    }

    static func twelveExportLine() -> String? {
        line(for: twelveExportKey, prefix: "Last Markdown export")
    }

    static func twelveMirrorLine() -> String? {
        line(for: twelveMirrorKey, prefix: "Last iCloud mirror")
    }

    static func ledgerExportLine() -> String? {
        line(for: ledgerExportKey, prefix: "Last CSV export")
    }

    static func ledgerMirrorLine() -> String? {
        line(for: ledgerMirrorKey, prefix: "Last iCloud mirror")
    }

    private static func line(for key: String, prefix: String) -> String? {
        let t = UserDefaults.standard.double(forKey: key)
        guard t > 0 else { return nil }
        let d = Date(timeIntervalSince1970: t)
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return "\(prefix): \(f.string(from: d))"
    }
}

extension Notification.Name {
    static let appFontScaleDidChange = Notification.Name("appFontScaleDidChange")
}
