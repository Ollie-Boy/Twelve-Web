import SwiftUI
import UIKit

struct EntryCardView: View {
    let entry: DiaryEntry
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private static let topBandHeight: CGFloat = 154
    /// 154 image + tighter meta block (weather, title, attachments).
    private static let cardFixedHeight: CGFloat = 274

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

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    topBand
                        .frame(height: Self.topBandHeight)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Label(entry.weather.title, systemImage: entry.weather.symbol)
                                .font(TwelveTheme.appFont(size: 10, weight: .semibold))
                                .foregroundStyle(TwelveTheme.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text(entry.selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                                .font(TwelveTheme.appFont(size: 11, weight: .semibold))
                                .foregroundStyle(TwelveTheme.textSecondary)
                        }

                        if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(entry.title)
                                .font(TwelveTheme.appFont(size: 16, weight: .semibold))
                                .foregroundStyle(TwelveTheme.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 4)
                        }

                        if !entry.attachments.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "paperclip")
                                Text("\(entry.attachments.count) attachment\(entry.attachments.count > 1 ? "s" : "")")
                            }
                            .font(TwelveTheme.appFont(size: 10, weight: .medium))
                            .foregroundStyle(TwelveTheme.textTertiary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Self.cardFixedHeight, alignment: .top)

                Text(dateText)
                    .font(TwelveTheme.appFont(size: 11, weight: .medium))
                    .foregroundStyle(TwelveTheme.textTertiary)
                    .padding(.trailing, 16)
                    .padding(.bottom, 10)
                    .allowsHitTesting(false)
            }
            .background(TwelveTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(TwelveTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: TwelveTheme.cardShadow, radius: 18, y: 10)
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
        } else {
            placeholderCoverBand
        }
    }

    private var placeholderCoverBand: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TwelveTheme.placeholderCoverTop,
                    TwelveTheme.placeholderCoverBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { idx in
                    Capsule()
                        .fill(TwelveTheme.entryPlaceholderCapsuleBase.opacity(1.0 - Double(idx) * 0.12))
                        .frame(width: 230 + CGFloat(idx * 30), height: 12)
                        .offset(x: idx % 2 == 0 ? -28 : 30, y: CGFloat(idx * 8))
                }
            }

            VStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(TwelveTheme.appFont(size: 28, weight: .semibold))
                Text("Twelve")
                    .font(TwelveTheme.appFont(size: 20, weight: .semibold))
            }
            .foregroundStyle(TwelveTheme.textPrimary.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.topBandHeight)
        .clipped()
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
                .fill(TwelveTheme.secondarySurface.opacity(0.4))
        }
    }
}
