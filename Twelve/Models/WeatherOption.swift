import Foundation

enum WeatherOption: String, CaseIterable, Codable, Identifiable {
    case none
    case sunny
    case cloudy
    case rainy
    case windy
    case snowy
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "No Weather"
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
        case .none:
            return "minus.circle"
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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "none"
        self = WeatherOption(rawValue: rawValue) ?? .none
    }

    static func suggestedForRecognizedAddress(_ address: String, date: Date) -> WeatherOption {
        let lowercase = address.lowercased()
        if lowercase.contains("snow") || lowercase.contains("ice") {
            return .snowy
        }
        if lowercase.contains("rain") || lowercase.contains("storm") {
            return .rainy
        }
        if lowercase.contains("wind") {
            return .windy
        }
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 6 && hour <= 17 {
            return .sunny
        }
        return .cloudy
    }
}
