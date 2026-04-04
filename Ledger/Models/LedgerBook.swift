import Foundation

struct LedgerBook: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String

    static let defaultId = "default"
    static let defaultName = "Main"
}

@MainActor
final class LedgerBookStore: ObservableObject {
    private static let booksKey = "ledger.books.v1"
    private static let activeKey = "ledger.activeBookId"

    @Published private(set) var books: [LedgerBook]
    @Published var activeBookId: String {
        didSet {
            UserDefaults.standard.set(activeBookId, forKey: Self.activeKey)
        }
    }

    init() {
        let loaded: [LedgerBook]
        if let data = UserDefaults.standard.data(forKey: Self.booksKey),
           let decoded = try? JSONDecoder().decode([LedgerBook].self, from: data),
           !decoded.isEmpty {
            loaded = decoded
        } else {
            loaded = [LedgerBook(id: LedgerBook.defaultId, name: LedgerBook.defaultName)]
        }
        let saved = UserDefaults.standard.string(forKey: Self.activeKey)
        let initialActive: String
        if let saved, loaded.contains(where: { $0.id == saved }) {
            initialActive = saved
        } else {
            initialActive = LedgerBook.defaultId
        }
        books = loaded
        activeBookId = initialActive
    }

    func addBook(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let id = UUID().uuidString
        books.append(LedgerBook(id: id, name: trimmed))
        persistBooks()
    }

    func renameBook(id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let i = books.firstIndex(where: { $0.id == id }) else { return }
        books[i].name = trimmed
        persistBooks()
    }

    func deleteBook(id: String) {
        guard id != LedgerBook.defaultId else { return }
        books.removeAll { $0.id == id }
        if books.isEmpty {
            books = [LedgerBook(id: LedgerBook.defaultId, name: LedgerBook.defaultName)]
        }
        if activeBookId == id {
            activeBookId = LedgerBook.defaultId
        }
        persistBooks()
    }

    func setActiveBook(_ id: String) {
        guard books.contains(where: { $0.id == id }) else { return }
        activeBookId = id
    }

    private func persistBooks() {
        if let data = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(data, forKey: Self.booksKey)
        }
    }
}
