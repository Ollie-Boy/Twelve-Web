import SwiftUI
import UIKit

struct EntryCardView: View {
    let entry: DiaryEntry
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var rotatingCoverIndex: Int = 0
    private let coverRotationTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

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

    private var initialCoverIndex: Int {
        guard !imageAttachments.isEmpty else { return 0 }
        let hash = abs(entry.id.uuidString.hashValue)
        return hash % imageAttachments.count
    }

    private var currentCoverAttachment: DiaryAttachment? {
        guard !imageAttachments.isEmpty else { return nil }
        let safeIndex = rotatingCoverIndex % imageAttachments.count
        return imageAttachments[safeIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            coverView

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(entry.weather.title, systemImage: entry.weather.symbol)
                        .font(BreezyTheme.appFont(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                    Spacer()
                    Text(entry.selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(BreezyTheme.appFont(size: 13, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textSecondary)
                }

                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.title)
                        .font(BreezyTheme.appFont(size: 24, weight: .bold))
                        .foregroundStyle(BreezyTheme.textPrimary)
                }

                Text(entry.body)
                    .font(BreezyTheme.appFont(size: 15))
                    .foregroundStyle(BreezyTheme.textSecondary)
                    .lineLimit(3)

                if !entry.attachments.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "paperclip")
                        Text("\(entry.attachments.count) attachment\(entry.attachments.count > 1 ? "s" : "")")
                    }
                    .font(BreezyTheme.appFont(size: 12, weight: .medium))
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
                .font(BreezyTheme.appFont(size: 11, weight: .medium))
                .foregroundStyle(BreezyTheme.textTertiary)
                .padding(.trailing, 16)
                .padding(.bottom, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            onOpen()
        }
        .onAppear {
            rotatingCoverIndex = initialCoverIndex
        }
        .onReceive(coverRotationTimer) { _ in
            guard imageAttachments.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.55)) {
                rotatingCoverIndex = (rotatingCoverIndex + 1) % imageAttachments.count
            }
        }
    }

    @ViewBuilder
    private var coverView: some View {
        if imageAttachments.count > 1 {
            ZStack {
                ForEach(Array(imageAttachments.enumerated()), id: \.element.id) { index, attachment in
                    coverImageView(for: attachment)
                        .opacity(index == rotatingCoverIndex ? 1 : 0)
                }
            }
            .animation(.easeInOut(duration: 0.55), value: rotatingCoverIndex)
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
                        .font(BreezyTheme.appFont(size: 28, weight: .semibold))
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
