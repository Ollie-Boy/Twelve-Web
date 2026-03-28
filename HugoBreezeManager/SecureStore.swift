import Foundation
import Security

enum SecureStoreError: Error {
    case encodingFailed
    case decodingFailed
    case unhandledStatus(OSStatus)
}

struct SecureStore {
    private static let service = "com.hugobreeze.manager"
    private static let authAccount = "auth.session"
    private static let repoAccount = "repo.settings"

    static func saveAuth(_ auth: AuthSession) throws {
        let data = try JSONEncoder().encode(auth)
        guard let raw = String(data: data, encoding: .utf8) else {
            throw SecureStoreError.encodingFailed
        }
        try save(raw, account: authAccount)
    }

    static func loadAuth() throws -> AuthSession? {
        guard let raw = try load(account: authAccount) else {
            return nil
        }
        guard let data = raw.data(using: .utf8) else {
            throw SecureStoreError.decodingFailed
        }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    static func clearAuth() throws {
        try delete(account: authAccount)
    }

    static func saveRepo(_ repo: RepoSettings) throws {
        let data = try JSONEncoder().encode(repo)
        guard let raw = String(data: data, encoding: .utf8) else {
            throw SecureStoreError.encodingFailed
        }
        try save(raw, account: repoAccount)
    }

    static func loadRepo() throws -> RepoSettings? {
        guard let raw = try load(account: repoAccount) else {
            return nil
        }
        guard let data = raw.data(using: .utf8) else {
            throw SecureStoreError.decodingFailed
        }
        return try JSONDecoder().decode(RepoSettings.self, from: data)
    }

    private static func save(_ value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStoreError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStoreError.unhandledStatus(status)
        }
    }

    private static func load(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SecureStoreError.unhandledStatus(status)
        }
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw SecureStoreError.decodingFailed
        }
        return value
    }

    private static func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStoreError.unhandledStatus(status)
        }
    }
}
