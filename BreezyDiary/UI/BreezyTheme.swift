import SwiftUI

enum BreezyTheme {
    static let skyBlue = Color(red: 0.84, green: 0.93, blue: 1.0)
    static let softBlueBackground = Color(red: 0.90, green: 0.95, blue: 1.0)
    static let cardWhite = Color.white
    static let whiteCard = Color.white
    static let softYellow = Color(red: 1.0, green: 0.96, blue: 0.76)
    static let accentYellow = Color(red: 1.0, green: 0.94, blue: 0.70)
    static let deepBlue = Color(red: 0.16, green: 0.27, blue: 0.45)
    static let skyBlueDark = Color(red: 0.23, green: 0.45, blue: 0.72)
    static let textPrimary = deepBlue
    static let textSecondary = Color(red: 0.35, green: 0.47, blue: 0.64)

    static let cardGradient = LinearGradient(
        colors: [Color.white, Color(red: 0.94, green: 0.97, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
