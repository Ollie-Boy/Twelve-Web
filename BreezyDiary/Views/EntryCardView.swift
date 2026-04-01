import SwiftUI
import UIKit

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

    private var imageAttachments: [DiaryAttachment] {
        entry.attachments.filter { $0.kind == .image || $0.kind == .gif }
    }

    private func rotatingCoverAttachment(for date: Date) -> DiaryAttachment? {
        guard !imageAttachments.isEmpty else { return nil }
        if imageAttachments.count == 1 {
            return imageAttachments[0]
        }
        let tick = Int(date.timeIntervalSinceReferenceDate / 4.0)
        let base = abs(entry.id.uuidString.hashValue)
        let index = (base + tick) % imageAttachments.count
        return imageAttachments[index]
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                coverView

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
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
                .padding(.top, 2)
            }
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

    @ViewBuilder
    private var coverView: some View {
        if imageAttachments.count > 1 {
            TimelineView(.periodic(from: .now, by: 4.0)) { context in
                coverImageView(for: rotatingCoverAttachment(for: context.date))
            }
        } else {
            coverImageView(for: imageAttachments.first)
        }
    }

    @ViewBuilder
    private func coverImageView(for attachment: DiaryAttachment?) -> some View {
        if let attachment, let image = UIImage(contentsOfFile: attachment.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 154)
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.80, green: 0.90, blue: 1.00),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { idx in
                        Capsule()
                            .fill(Color.white.opacity(0.55 - Double(idx) * 0.10))
                            .frame(width: 230 + CGFloat(idx * 30), height: 12)
                            .offset(x: idx % 2 == 0 ? -28 : 30, y: CGFloat(idx * 8))
                    }
                }

                VStack(spacing: 8) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 28, weight: .semibold))
                    Text("Twelve")
                        .font(BreezyTheme.handwrittenFont(size: 20))
                }
                .foregroundStyle(BreezyTheme.textPrimary.opacity(0.72))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 154)
        }
    }
}
