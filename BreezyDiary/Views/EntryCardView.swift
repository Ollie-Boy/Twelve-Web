import SwiftUI

struct EntryCardView: View {
    let entry: DiaryEntry
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

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
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(entry.weather.title, systemImage: entry.weather.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                    Spacer()
                    Text(entry.selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textSecondary)
                }

                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(BreezyTheme.textPrimary)
                }

                Text(entry.body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .lineLimit(3)

                if !entry.attachments.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "paperclip")
                        Text("\(entry.attachments.count) attachment\(entry.attachments.count > 1 ? "s" : "")")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BreezyTheme.textTertiary)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BreezyTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(BreezyTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: BreezyTheme.cardShadow, radius: 18, y: 10)
            .overlay(alignment: .bottomTrailing) {
                Text(dateText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BreezyTheme.textTertiary)
                    .padding(.trailing, 16)
                    .padding(.bottom, 14)
            }
        }
        .buttonStyle(.plain)
    }
}
