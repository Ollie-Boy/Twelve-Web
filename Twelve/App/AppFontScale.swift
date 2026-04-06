import Foundation
import UIKit

/// Per-app UI text scale (compact / standard / large). Persisted; TwelveTheme reads via bundle id.
enum AppFontScale: String, CaseIterable, Identifiable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .large: return "Large"
        }
    }

    var multiplier: CGFloat {
        switch self {
        case .compact: return 0.92
        case .standard: return 1.0
        case .large: return 1.12
        }
    }

    private static var defaultsKey: String {
        let id = Bundle.main.bundleIdentifier ?? ""
        return id.contains("Ledger") ? "ledger.fontScale" : "twelve.fontScale"
    }

    static var current: AppFontScale {
        let raw = UserDefaults.standard.string(forKey: defaultsKey) ?? AppFontScale.standard.rawValue
        return AppFontScale(rawValue: raw) ?? .standard
    }

    static func setCurrent(_ v: AppFontScale) {
        UserDefaults.standard.set(v.rawValue, forKey: defaultsKey)
    }

    /// Multiply design-time font sizes (TwelveTheme.appFont base sizes).
    static var multiplierForCurrentApp: CGFloat {
        current.multiplier
    }
}
