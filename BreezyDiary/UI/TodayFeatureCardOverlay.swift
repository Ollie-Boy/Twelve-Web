import SwiftUI

struct TodayFeatureCardOverlay: View {
    @Binding var isPresented: Bool
    var onStartWriting: () -> Void = {}

    var body: some View {
        ZStack {
            BreezyTheme.overlayDim
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    LinearGradient(
                        colors: [
                            BreezyTheme.todayCardBlueStart,
                            BreezyTheme.todayCardBlueEnd,
                            BreezyTheme.todayCardYellow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("TODAY")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BreezyTheme.textSecondary)
                        Text("Breezy Diary")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(BreezyTheme.textPrimary)
                        Text("Capture gentle moments in a calm, card-style journal.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(BreezyTheme.textSecondary)
                            .lineSpacing(3)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                }
                .frame(height: 290)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Offline. Private. Playful.")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textPrimary)

                    Text("Write with animated text feel, adjust date and weather, and save everything locally on your iPhone.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(BreezyTheme.textSecondary)
                        .lineSpacing(3)

                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Not now")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))

                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                                isPresented = false
                            }
                            onStartWriting()
                        } label: {
                            Label("Start Writing", systemImage: "sparkles")
                        }
                        .buttonStyle(BreezyPrimaryButtonStyle())
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BreezyTheme.surface)
            }
            .frame(maxWidth: 540)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(0.20), radius: 28, y: 18)
            .padding(.horizontal, 20)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BreezyTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(14)
            }
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.96).combined(with: .opacity),
                    removal: .scale(scale: 0.98).combined(with: .opacity)
                )
            )
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            isPresented = false
        }
    }
}
