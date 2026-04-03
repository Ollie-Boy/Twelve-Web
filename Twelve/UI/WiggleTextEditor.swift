import SwiftUI

struct WiggleTextEditor: View {
    @Binding var text: String
    @State private var wiggleAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        TextEditor(text: $text)
            .font(TwelveTheme.appFont(size: 18))
            .foregroundStyle(TwelveTheme.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(14)
            .frame(minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TwelveTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(TwelveTheme.strokeSoft, lineWidth: 1)
                    )
            )
            .rotationEffect(.degrees(wiggleAngle))
            .offset(y: bounceOffset)
            .onChange(of: text) { _, _ in
                InputWiggleAnimation.play(
                    setAngle: { wiggleAngle = $0 },
                    setOffset: { bounceOffset = $0 }
                )
            }
    }
}
