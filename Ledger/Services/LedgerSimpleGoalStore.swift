import Foundation

/// Optional per-book "save at least this much net per month" target (same month semantics as summary panel).
enum LedgerSimpleGoalStore {
    private static let key = "ledger.simpleGoal.savingsTarget.v1"

    private static func loadMap() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }

    private static func saveMap(_ map: [String: String]) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func savingsTarget(for bookId: String) -> Decimal? {
        guard let s = loadMap()[bookId]?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty,
              let d = LedgerDecimalFormatting.parseAmount(from: s), d > 0
        else { return nil }
        return LedgerDecimalFormatting.round(d)
    }

    static func setSavingsTargetString(_ raw: String, for bookId: String) {
        var map = loadMap()
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            map.removeValue(forKey: bookId)
        } else if let d = LedgerDecimalFormatting.parseAmount(from: t), d > 0 {
            map[bookId] = NSDecimalNumber(decimal: LedgerDecimalFormatting.round(d)).stringValue
        } else {
            map.removeValue(forKey: bookId)
        }
        saveMap(map)
    }
}
