import SwiftUI

enum AppearancePreference: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@MainActor
final class AppearanceStore: ObservableObject {
    private let storageKey: String
    private let legacyStorageKey: String?

    @Published private(set) var preference: AppearancePreference

    /// - Parameters:
    ///   - storageKey: UserDefaults key for this app (Ledger uses its own so it does not share with Twelve).
    ///   - legacyStorageKey: Optional migration source; nil skips legacy import.
    init(storageKey: String = "twelveAppearancePreference", legacyStorageKey: String? = "breezyAppearancePreference") {
        self.storageKey = storageKey
        self.legacyStorageKey = legacyStorageKey
        let defaults = UserDefaults.standard
        let raw: Int
        if let v = defaults.object(forKey: storageKey) as? Int {
            raw = v
        } else if let legacyKey = legacyStorageKey,
                  let legacy = defaults.object(forKey: legacyKey) as? Int {
            raw = legacy
            defaults.set(legacy, forKey: storageKey)
            defaults.removeObject(forKey: legacyKey)
        } else {
            raw = AppearancePreference.system.rawValue
        }
        preference = AppearancePreference(rawValue: raw) ?? .system
    }

    func setPreference(_ newValue: AppearancePreference) {
        guard newValue != preference else { return }
        preference = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
    }

    var preferredColorScheme: ColorScheme? {
        switch preference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
