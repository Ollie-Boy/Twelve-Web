import Foundation

/// Optional mirror of local JSON to the iCloud Documents container when available.
/// Enable **iCloud → iCloud Documents** for the app target in Xcode; otherwise `ubiquityURL` is nil and this no-ops.
enum ICloudDataMirror {
    private static let twelveEnabledKey = "twelve.icloud.mirror.enabled"
    private static let ledgerEnabledKey = "ledger.icloud.mirror.enabled"

    static var twelveEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: twelveEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: twelveEnabledKey) }
    }

    static var ledgerEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: ledgerEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: ledgerEnabledKey) }
    }

    private static func ubiquityRoot() -> URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }

    static func mirrorTwelveDiaryJSON(_ data: Data) {
        guard twelveEnabled, let root = ubiquityRoot() else { return }
        let url = root.appendingPathComponent("Documents/Twelve/diary-entries.json")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    static func mirrorLedgerJSON(_ data: Data) {
        guard ledgerEnabled, let root = ubiquityRoot() else { return }
        let url = root.appendingPathComponent("Documents/Ledger/transactions.json")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    static func twelveMirrorStatusLine() -> String {
        if ubiquityRoot() == nil {
            return "iCloud container not configured in Xcode (add iCloud Documents capability)."
        }
        return twelveEnabled ? "Diary data is copied to iCloud when you save." : "Mirror is off."
    }

    static func ledgerMirrorStatusLine() -> String {
        if ubiquityRoot() == nil {
            return "iCloud container not configured in Xcode (add iCloud Documents capability)."
        }
        return ledgerEnabled ? "Ledger data is copied to iCloud when you save." : "Mirror is off."
    }
}
