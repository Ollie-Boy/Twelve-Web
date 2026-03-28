import SwiftUI

struct EntryCardView: View {
    let entry: DiaryEntry

    private var dateText: String {
        entry.selectedDate.formatted(
            Date.FormatStyle()
                .year()
                .month(.wide)
                .day()
                .hour(.twoDigits(amPM: .wide))
                .minute(.twoDigits)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(entry.weather.title, systemImage: entry.weather.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BreezyTheme.deepBlue)

                Spacer()

                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !entry.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label(entry.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.title)
                    .font(.headline)
                    .foregroundStyle(BreezyTheme.textPrimary)
            }

            Text(entry.body)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BreezyTheme.whiteCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(BreezyTheme.skyBlue.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: BreezyTheme.skyBlue.opacity(0.15), radius: 12, y: 6)
        )
    }
}
