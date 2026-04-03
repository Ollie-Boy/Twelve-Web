import SwiftUI

/// Shared spring wiggle used for diary text inputs (matches `WiggleTextEditor`).
enum InputWiggleAnimation {
    static func play(
        setAngle: @escaping (Double) -> Void,
        setOffset: @escaping (CGFloat) -> Void
    ) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            setAngle(1.8)
            setOffset(-3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                setAngle(-1.8)
                setOffset(2)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
                setAngle(0)
                setOffset(0)
            }
        }
    }
}

/// Wiggles the view whenever `value` changes (each keystroke for `String` bindings).
struct WiggleOnChangeModifier<Value: Equatable>: ViewModifier {
    let value: Value
    @State private var wiggleAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(wiggleAngle))
            .offset(y: bounceOffset)
            .onChange(of: value) { _, _ in
                InputWiggleAnimation.play(
                    setAngle: { wiggleAngle = $0 },
                    setOffset: { bounceOffset = $0 }
                )
            }
    }
}

extension View {
    func wiggleOnInputChange<Value: Equatable>(_ value: Value) -> some View {
        modifier(WiggleOnChangeModifier(value: value))
    }
}
