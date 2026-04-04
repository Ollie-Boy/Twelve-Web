import Foundation

final class LedgerStorage {
    private let key = "ledger.transactions.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadEntries() -> [LedgerEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try decoder.decode([LedgerEntry].self, from: data)
        } catch {
            return []
        }
    }

    func saveEntries(_ entries: [LedgerEntry]) {
        do {
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: key)
            ICloudDataMirror.mirrorLedgerJSON(data)
        } catch {}
    }
}
