import Foundation

final class DiaryStorage {
    private let key = "breezy.diary.entries"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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
