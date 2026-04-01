import SwiftUI
import UIKit

enum BreezyTheme {
    static let backgroundTop = Color(red: 0.97, green: 0.98, blue: 1.00)
    static let backgroundBottom = Color(red: 0.95, green: 0.97, blue: 1.00)
    static let background = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surface = Color.white
    static let secondarySurface = Color(red: 0.98, green: 0.99, blue: 1.00)
    static let surfaceTintBlue = Color(red: 0.92, green: 0.96, blue: 1.00)

    static let primaryBlue = Color(red: 0.00, green: 0.48, blue: 1.00)
    static let primaryBlueDark = Color(red: 0.02, green: 0.35, blue: 0.88)
    static let softBlue = Color(red: 0.90, green: 0.95, blue: 1.00)
    static let accentYellow = Color(red: 1.00, green: 0.95, blue: 0.80)
    static let softYellow = Color(red: 1.00, green: 0.96, blue: 0.86)

    static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let textSecondary = Color(red: 0.41, green: 0.43, blue: 0.47)
    static let textTertiary = Color(red: 0.56, green: 0.58, blue: 0.62)

    static let hairline = Color.black.opacity(0.06)
    static let strokeSoft = Color.black.opacity(0.08)
    static let cardBorder = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.08)
    static let cardShadow = Color.black.opacity(0.08)
    static let overlayDim = Color.black.opacity(0.34)
    static let todayFeatureScrim = Color.black.opacity(0.40)

    static let cardBackground = Color.white
    static let cardSurface = Color.white

    static let cloudTint = Color.white
    static let windLine = Color(red: 0.80, green: 0.87, blue: 0.96)

    static let todayCardBlueStart = Color(red: 0.80, green: 0.90, blue: 1.00)
    static let todayCardBlueEnd = Color(red: 0.92, green: 0.96, blue: 1.00)
    static let todayCardYellow = Color(red: 1.00, green: 0.95, blue: 0.82)
    static let todayCardTextOnImage = Color.white
    static let todayFeatureDetailBackground = Color(red: 0.96, green: 0.97, blue: 1.00)
    static let todayFeatureDetailCard = Color.white
    static let todayFeatureDetailStroke = Color.black.opacity(0.08)
    static let todayFeatureCloseBackground = Color.black.opacity(0.24)
    static let todayFeatureCloseIcon = Color.white

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
}
