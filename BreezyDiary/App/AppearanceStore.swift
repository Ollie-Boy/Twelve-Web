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
    private static let storageKey = "breezyAppearancePreference"

    @Published private(set) var preference: AppearancePreference

    init() {
        let raw = UserDefaults.standard.object(forKey: Self.storageKey) as? Int ?? AppearancePreference.system.rawValue
        preference = AppearancePreference(rawValue: raw) ?? .system
    }

    func setPreference(_ newValue: AppearancePreference) {
        guard newValue != preference else { return }
        preference = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: Self.storageKey)
    }

    var preferredColorScheme: ColorScheme? {
        switch preference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
