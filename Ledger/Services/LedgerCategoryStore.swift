import Foundation

enum LedgerCategoryStore {
    private static let key = "ledger.category.presets.v1"

    static func load(for bookId: String) -> [String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let map = try? JSONDecoder().decode([String: [String]].self, from: data),
              let list = map[bookId], !list.isEmpty
        else {
            return ["Food", "Transport", "Shopping", "Bills", "Salary", "Other"]
        }
        return list
    }

    static func save(_ categories: [String], for bookId: String) {
        var map: [String: [String]] = [:]
        if let data = UserDefaults.standard.data(forKey: key),
           let existing = try? JSONDecoder().decode([String: [String]].self, from: data) {
            map = existing
        }
        let cleaned = categories.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        map[bookId] = Array(Set(cleaned)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func rememberCategory(_ category: String, bookId: String) {
        let t = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var list = load(for: bookId)
        if !list.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) {
            list.append(t)
            save(list, for: bookId)
        }
    }
}
