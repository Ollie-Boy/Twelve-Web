import Foundation

final class DiaryStorage {
    private let key = "twelve.diary.entries"
    private let legacyKey = "breezy.diary.entries"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        migrateLegacyIfNeeded()
    }

    private func migrateLegacyIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.data(forKey: key) == nil,
              let legacy = defaults.data(forKey: legacyKey),
              !legacy.isEmpty
        else { return }
        defaults.set(legacy, forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }

    func loadEntries() -> [DiaryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }

        do {
            return try decoder.decode([DiaryEntry].self, from: data)
        } catch {
            return []
        }
    }

    func saveEntries(_ entries: [DiaryEntry]) {
        do {
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // Keep local-only app resilient even if encoding fails.
        }
    }
}
