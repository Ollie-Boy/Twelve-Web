import SwiftUI
import UIKit

enum TwelveTheme {
    private static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    static let backgroundTop = adaptive(
        UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1),
        UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1)
    )
    static let backgroundBottom = adaptive(
        UIColor(red: 0.95, green: 0.97, blue: 1.00, alpha: 1),
        UIColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 1)
    )
    static let background = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surface = adaptive(
        .white,
        UIColor(red: 0.14, green: 0.16, blue: 0.21, alpha: 1)
    )
    static let secondarySurface = adaptive(
        UIColor(red: 0.98, green: 0.99, blue: 1.00, alpha: 1),
        UIColor(red: 0.11, green: 0.13, blue: 0.18, alpha: 1)
    )
    static let surfaceTintBlue = adaptive(
        UIColor(red: 0.92, green: 0.96, blue: 1.00, alpha: 1),
        UIColor(red: 0.16, green: 0.24, blue: 0.38, alpha: 1)
    )

    static let primaryBlue = adaptive(
        UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1),
        UIColor(red: 0.35, green: 0.62, blue: 1.00, alpha: 1)
    )
    static let primaryBlueDark = adaptive(
        UIColor(red: 0.02, green: 0.35, blue: 0.88, alpha: 1),
        UIColor(red: 0.22, green: 0.48, blue: 0.95, alpha: 1)
    )
    static let softBlue = adaptive(
        UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1),
        UIColor(red: 0.14, green: 0.22, blue: 0.36, alpha: 1)
    )
    static let accentYellow = adaptive(
        UIColor(red: 1.00, green: 0.95, blue: 0.80, alpha: 1),
        UIColor(red: 0.32, green: 0.26, blue: 0.14, alpha: 1)
    )
    static let softYellow = adaptive(
        UIColor(red: 1.00, green: 0.96, blue: 0.86, alpha: 1),
        UIColor(red: 0.28, green: 0.24, blue: 0.14, alpha: 1)
    )

    static let textPrimary = adaptive(
        UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1),
        UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
    )
    static let textSecondary = adaptive(
        UIColor(red: 0.41, green: 0.43, blue: 0.47, alpha: 1),
        UIColor(red: 0.68, green: 0.72, blue: 0.78, alpha: 1)
    )
    static let textTertiary = adaptive(
        UIColor(red: 0.56, green: 0.58, blue: 0.62, alpha: 1),
        UIColor(red: 0.52, green: 0.55, blue: 0.60, alpha: 1)
    )

    static let hairline = adaptive(
        UIColor(white: 0, alpha: 0.06),
        UIColor(white: 1, alpha: 0.10)
    )
    static let strokeSoft = adaptive(
        UIColor(white: 0, alpha: 0.08),
        UIColor(white: 1, alpha: 0.12)
    )
    static let cardBorder = adaptive(
        UIColor(white: 0, alpha: 0.06),
        UIColor(white: 1, alpha: 0.08)
    )
    static let shadow = adaptive(
        UIColor(white: 0, alpha: 0.08),
        UIColor(white: 0, alpha: 0.45)
    )
    static let cardShadow = adaptive(
        UIColor(white: 0, alpha: 0.08),
        UIColor(white: 0, alpha: 0.55)
    )
    static let overlayDim = adaptive(
        UIColor(white: 0, alpha: 0.34),
        UIColor(white: 0, alpha: 0.62)
    )
    static let todayFeatureScrim = adaptive(
        UIColor(white: 0, alpha: 0.40),
        UIColor(white: 0, alpha: 0.50)
    )

    static let cardBackground = surface
    static let cardSurface = surface

    static let cloudTint = adaptive(
        .white,
        UIColor(red: 0.55, green: 0.65, blue: 0.85, alpha: 1)
    )
    static let windLine = adaptive(
        UIColor(red: 0.80, green: 0.87, blue: 0.96, alpha: 1),
        UIColor(red: 0.28, green: 0.38, blue: 0.52, alpha: 1)
    )

    static let todayCardBlueStart = adaptive(
        UIColor(red: 0.80, green: 0.90, blue: 1.00, alpha: 1),
        UIColor(red: 0.12, green: 0.22, blue: 0.42, alpha: 1)
    )
    static let todayCardBlueEnd = adaptive(
        UIColor(red: 0.92, green: 0.96, blue: 1.00, alpha: 1),
        UIColor(red: 0.10, green: 0.16, blue: 0.32, alpha: 1)
    )
    static let todayCardYellow = adaptive(
        UIColor(red: 1.00, green: 0.95, blue: 0.82, alpha: 1),
        UIColor(red: 0.22, green: 0.18, blue: 0.10, alpha: 1)
    )
    static let todayCardTextOnImage = adaptive(
        .white,
        UIColor(red: 0.96, green: 0.97, blue: 1.00, alpha: 1)
    )
    static let todayFeatureDetailBackground = adaptive(
        UIColor(red: 0.96, green: 0.97, blue: 1.00, alpha: 1),
        UIColor(red: 0.10, green: 0.12, blue: 0.17, alpha: 1)
    )
    static let todayFeatureDetailCard = surface
    static let todayFeatureDetailStroke = hairline
    static let todayFeatureCloseBackground = adaptive(
        UIColor(white: 0, alpha: 0.24),
        UIColor(white: 0, alpha: 0.45)
    )
    static let todayFeatureCloseIcon: Color = .white

    /// Decorative highlights on marketing hero art (adapts orb opacity for dark backgrounds).
    static let heroOrbPrimary = adaptive(
        UIColor(white: 1, alpha: 0.35),
        UIColor(white: 1, alpha: 0.14)
    )
    static let heroOrbSecondary = adaptive(
        UIColor(white: 1, alpha: 0.22),
        UIColor(white: 1, alpha: 0.09)
    )
    static let heroBarWide = adaptive(
        UIColor(white: 1, alpha: 0.55),
        UIColor(white: 1, alpha: 0.20)
    )
    static let heroBarNarrow = adaptive(
        UIColor(white: 1, alpha: 0.45),
        UIColor(white: 1, alpha: 0.16)
    )
    static let heroCardStroke = adaptive(
        UIColor(white: 1, alpha: 0.56),
        UIColor(white: 1, alpha: 0.22)
    )
    static let heroSwipeHintBackground = adaptive(
        UIColor(white: 0, alpha: 0.14),
        UIColor(white: 0, alpha: 0.35)
    )

    static let placeholderCoverTop = adaptive(
        UIColor(red: 0.80, green: 0.90, blue: 1.00, alpha: 1),
        UIColor(red: 0.18, green: 0.28, blue: 0.48, alpha: 1)
    )
    static let placeholderCoverBottom = adaptive(
        UIColor.white,
        UIColor(red: 0.10, green: 0.13, blue: 0.20, alpha: 1)
    )

    /// Horizontal “paper” stripes on the imageless entry cover.
    static let entryPlaceholderCapsuleBase = adaptive(
        UIColor(white: 1, alpha: 0.55),
        UIColor(white: 1, alpha: 0.14)
    )

    static let modalCardShadow = adaptive(
        UIColor(white: 0, alpha: 0.22),
        UIColor(white: 0, alpha: 0.55)
    )

    static func handwrittenFont(size: CGFloat) -> Font {
        if UIFont(name: "Noteworthy-Bold", size: size) != nil {
            return .custom("Noteworthy-Bold", size: size)
        }
        if UIFont(name: "ChalkboardSE-Bold", size: size) != nil {
            return .custom("ChalkboardSE-Bold", size: size)
        }
        return .system(size: size, weight: .semibold, design: .rounded)
    }

    static func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIFont(name: "ChalkboardSE-Regular", size: size) != nil {
            switch weight {
            case .bold, .heavy, .black:
                return .custom("ChalkboardSE-Bold", size: size)
            case .semibold, .medium:
                return .custom("ChalkboardSE-Bold", size: size)
            default:
                return .custom("ChalkboardSE-Regular", size: size)
            }
        }
        if UIFont(name: "Noteworthy-Light", size: size) != nil {
            switch weight {
            case .bold, .heavy, .black, .semibold, .medium:
                return .custom("Noteworthy-Bold", size: size)
            default:
                return .custom("Noteworthy-Light", size: size)
            }
        }
        if UIFont(name: "MarkerFelt-Wide", size: size) != nil {
            return .custom("MarkerFelt-Wide", size: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static var appTypographyDesign: Font.Design { .rounded }

    /// CSS `font-family` list for WKWebView body text to mirror `appFont` (Chalkboard / Noteworthy / Marker Felt / rounded system).
    static var webContentFontFamilyCSS: String {
        if UIFont(name: "ChalkboardSE-Regular", size: 12) != nil {
            return #"'Chalkboard SE', ChalkboardSE-Regular, 'ChalkboardSE-Regular', ui-rounded, system-ui, -apple-system, sans-serif"#
        }
        if UIFont(name: "Noteworthy-Light", size: 12) != nil {
            return #"'Noteworthy', Noteworthy-Light, 'Noteworthy-Light', ui-rounded, system-ui, -apple-system, sans-serif"#
        }
        if UIFont(name: "MarkerFelt-Wide", size: 12) != nil {
            return #"'Marker Felt', MarkerFelt-Wide, 'MarkerFelt-Wide', ui-rounded, system-ui, -apple-system, sans-serif"#
        }
        return "ui-rounded, 'SF Pro Rounded', system-ui, -apple-system, sans-serif"
    }
}
