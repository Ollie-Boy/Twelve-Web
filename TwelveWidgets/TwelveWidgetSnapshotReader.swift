import Foundation

enum TwelveWidgetSnapshotReader {
    static func load() -> (weather: String, date: String, lastTitle: String) {
        let d = UserDefaults(suiteName: WidgetSharedConstants.appGroupId)
        return (
            d?.string(forKey: "twelve.weather") ?? "—",
            d?.string(forKey: "twelve.date") ?? "",
            d?.string(forKey: "twelve.lastTitle") ?? ""
        )
    }
}
