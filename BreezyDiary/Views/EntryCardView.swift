import SwiftUI
import UIKit

struct EntryCardView: View {
    let entry: DiaryEntry
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private static let topBandHeight: CGFloat = 154
    /// Matches a typical card with photo: 154 band + meta (weather, 2-line title, 3-line body, attachment row, padding).
    private static let cardFixedHeight: CGFloat = 382

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

    private var hasImageCover: Bool {
        !imageAttachments.isEmpty
    }

    private var trimmedBody: String {
        entry.body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 12) {
                    topBand
                        .frame(height: Self.topBandHeight)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(entry.weather.title, systemImage: entry.weather.symbol)
                                .font(BreezyTheme.appFont(size: 12, weight: .semibold))
                                .foregroundStyle(BreezyTheme.textPrimary)
                            Spacer()
                            Text(entry.selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                                .font(BreezyTheme.appFont(size: 13, weight: .semibold))
                                .foregroundStyle(BreezyTheme.textSecondary)
                        }

                        if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(entry.title)
                                .font(BreezyTheme.appFont(size: 20, weight: .bold))
                                .foregroundStyle(BreezyTheme.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 8)
                        }

                        if hasImageCover, !trimmedBody.isEmpty {
                            Text(entry.body)
                                .font(BreezyTheme.appFont(size: 15))
                                .foregroundStyle(BreezyTheme.textSecondary)
                                .lineLimit(3)
                        }

                        if !entry.attachments.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "paperclip")
                                Text("\(entry.attachments.count) attachment\(entry.attachments.count > 1 ? "s" : "")")
                            }
                            .font(BreezyTheme.appFont(size: 12, weight: .medium))
                            .foregroundStyle(BreezyTheme.textTertiary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Self.cardFixedHeight, alignment: .top)

                Text(dateText)
                    .font(BreezyTheme.appFont(size: 11, weight: .medium))
                    .foregroundStyle(BreezyTheme.textTertiary)
                    .padding(.trailing, 16)
                    .padding(.bottom, 14)
                    .allowsHitTesting(false)
            }
            .background(BreezyTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(BreezyTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: BreezyTheme.cardShadow, radius: 18, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
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
    private var topBand: some View {
        if hasImageCover {
            coverView
        } else if !trimmedBody.isEmpty {
            ZStack(alignment: .bottom) {
                DiaryBodyContentView(text: entry.body, compactMaxHeight: Self.topBandHeight)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: BreezyTheme.cardSurface.opacity(0.25), location: 0.45),
                        .init(color: BreezyTheme.cardSurface.opacity(0.92), location: 0.82),
                        .init(color: BreezyTheme.cardSurface, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 52)
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .clipped()
        } else {
            Rectangle()
                .fill(BreezyTheme.secondarySurface.opacity(0.4))
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
                .frame(height: Self.topBandHeight)
                .clipped()
        } else {
            Rectangle()
                .fill(BreezyTheme.secondarySurface.opacity(0.4))
        }
    }
}
