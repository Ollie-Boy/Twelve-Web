import SwiftUI

struct EntryCardView: View {
    let entry: DiaryEntry
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(entry.weather.title, systemImage: entry.weather.symbol)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(BreezyTheme.softBlue.opacity(0.65))
                    )

                Spacer()

                Text(dateText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(BreezyTheme.textTertiary)
            }

            if !entry.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label(entry.location, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(BreezyTheme.textSecondary)
            }

            if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(BreezyTheme.textPrimary)
            }

            Text(entry.body)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(BreezyTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softYellow))

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(22)
        .background(BreezyTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(BreezyTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: BreezyTheme.cardShadow, radius: 18, y: 10)
    }
}
