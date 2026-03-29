import SwiftUI

struct WiggleTextEditor: View {
    @Binding var text: String
    @State private var wiggleAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 18, weight: .regular, design: .rounded))
            .foregroundStyle(BreezyTheme.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(14)
            .frame(minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BreezyTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BreezyTheme.strokeSoft, lineWidth: 1)
                    )
            )
            .rotationEffect(.degrees(wiggleAngle))
            .offset(y: bounceOffset)
            .onChange(of: text) { _ in
                playWiggle()
            }
    }

    private func playWiggle() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            wiggleAngle = 1.8
            bounceOffset = -3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                wiggleAngle = -1.8
                bounceOffset = 2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
                wiggleAngle = 0
                bounceOffset = 0
            }
        }
    }
}
