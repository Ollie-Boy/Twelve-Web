import SwiftUI
import WidgetKit

struct TwelveDiaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TwelveDiaryWidget", provider: TwelveProvider()) { entry in
            TwelveDiaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Twelve")
        .description("Weather, date, and your latest entry title.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct TwelveProvider: TimelineProvider {
    func placeholder(in context: Context) -> TwelveEntry {
        TwelveEntry(date: Date(), weather: "Sunny", dateLine: "Mon, Apr 1", lastTitle: "Open Twelve to refresh")
    }

    func getSnapshot(in context: Context, completion: @escaping (TwelveEntry) -> Void) {
        completion(snapshotEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TwelveEntry>) -> Void) {
        let e = snapshotEntry()
        completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(3600))))
    }

    private func snapshotEntry() -> TwelveEntry {
        let s = TwelveWidgetSnapshotReader.load()
        return TwelveEntry(date: Date(), weather: s.weather, dateLine: s.date, lastTitle: s.lastTitle.isEmpty ? "No entries yet" : s.lastTitle)
    }
}

private struct TwelveEntry: TimelineEntry {
    let date: Date
    let weather: String
    let dateLine: String
    let lastTitle: String
}

private struct TwelveDiaryWidgetView: View {
    var entry: TwelveEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Twelve")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(entry.weather)
                .font(.headline)
            Text(entry.dateLine)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(entry.lastTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .containerBackground(for: .widget) {
            Color(red: 0.95, green: 0.97, blue: 1.0)
        }
    }
}

struct LedgerNetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LedgerNetWidget", provider: LedgerProvider()) { entry in
            LedgerNetWidgetView(entry: entry)
        }
        .configurationDisplayName("Ledger")
        .description("This month’s net total in your currency.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct LedgerProvider: TimelineProvider {
    func placeholder(in context: Context) -> LedgerEntry2 {
        LedgerEntry2(date: Date(), net: "+$0.00", code: "USD")
    }

    func getSnapshot(in context: Context, completion: @escaping (LedgerEntry2) -> Void) {
        completion(snapshotEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LedgerEntry2>) -> Void) {
        let e = snapshotEntry()
        completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(3600))))
    }

    private func snapshotEntry() -> LedgerEntry2 {
        let s = LedgerWidgetSnapshotReader.load()
        return LedgerEntry2(date: Date(), net: s.net, code: s.code)
    }
}

private struct LedgerEntry2: TimelineEntry {
    let date: Date
    let net: String
    let code: String
}

private struct LedgerNetWidgetView: View {
    var entry: LedgerEntry2

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ledger")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("This month")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.net)
                .font(.title2.weight(.semibold))
            if !entry.code.isEmpty {
                Text(entry.code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .containerBackground(for: .widget) {
            Color(red: 0.95, green: 0.97, blue: 1.0)
        }
    }
}
