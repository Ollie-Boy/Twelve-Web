import Foundation

enum TwelveWidgetSnapshotReader {
    static func load() -> (weather: String, date: String, lastTitle: String) {
        let d = UserDefaults(suiteName: WidgetSharedConstants.appGroupId)
        func s(_ k: String, _ legacy: String) -> String {
            if let v = d?.string(forKey: k), !v.isEmpty { return v }
            return d?.string(forKey: legacy) ?? ""
        }
        let w = s("widget.v2.twelve.weather", "twelve.weather")
        let date = s("widget.v2.twelve.date", "twelve.date")
        let title = s("widget.v2.twelve.lastTitle", "twelve.lastTitle")
        return (w.isEmpty ? "—" : w, date, title)
    }
}
