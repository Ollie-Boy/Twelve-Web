import SwiftUI

/// Swipe left to reveal trailing capsule actions (Edit, Delete).
struct LedgerSwipeActionRow<Content: View>: View {
    var onEdit: () -> Void
    var onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var anchorOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0

    private let revealWidth: CGFloat = 168

    private var displayOffset: CGFloat {
        min(0, max(-revealWidth, anchorOffset + dragOffset))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 8) {
                editCapsule
                deleteCapsule
            }
            .padding(.trailing, 6)

            content()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .offset(x: displayOffset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 16, coordinateSpace: .local)
                        .onChanged { g in
                            let dx = g.translation.width
                            let dy = g.translation.height
                            guard abs(dx) > abs(dy) * 0.75 || abs(anchorOffset) > 1 else { return }
                            dragOffset = dx
                        }
                        .onEnded { g in
                            let dx = g.translation.width
                            let dy = g.translation.height
                            guard abs(dx) > abs(dy) * 0.65 else {
                                dragOffset = 0
                                return
                            }
                            let combined = anchorOffset + dx
                            let velocity = g.predictedEndTranslation.width - g.translation.width
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                if combined < -revealWidth * 0.45 || velocity < -80 {
                                    anchorOffset = -revealWidth
                                } else {
                                    anchorOffset = 0
                                }
                                dragOffset = 0
                            }
                        }
                )
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var editCapsule: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                anchorOffset = 0
            }
            onEdit()
        } label: {
            Text("Edit")
                .font(TwelveTheme.appFont(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [TwelveTheme.primaryBlue, TwelveTheme.primaryBlueDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private var deleteCapsule: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                anchorOffset = 0
            }
            onDelete()
        } label: {
            Text("Delete")
                .font(TwelveTheme.appFont(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.red.opacity(0.88)))
        }
        .buttonStyle(.plain)
    }
}
