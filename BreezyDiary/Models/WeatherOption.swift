import Foundation

enum WeatherOption: String, CaseIterable, Codable, Identifiable {
    case sunny
    case cloudy
    case rainy
    case windy
    case snowy
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sunny:
            return "Sunny"
        case .cloudy:
            return "Cloudy"
        case .rainy:
            return "Rainy"
        case .windy:
            return "Windy"
        case .snowy:
            return "Snowy"
        case .mixed:
            return "Mixed"
        }
    }

    var symbolName: String {
        switch self {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .windy:
            return "wind"
        case .snowy:
            return "snowflake"
        case .mixed:
            return "cloud.sun.fill"
        }
    }

    var symbol: String { symbolName }
}
