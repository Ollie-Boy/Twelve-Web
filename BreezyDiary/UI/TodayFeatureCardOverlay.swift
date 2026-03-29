import SwiftUI

struct TodayFeatureCardOverlay: View {
    @Binding var isPresented: Bool
    var onStartWriting: () -> Void = {}
    @State private var dragOffset: CGFloat = 0
    @State private var showDetail: Bool = false
    @Namespace private var todayCardNamespace

    var body: some View {
        ZStack {
            BreezyTheme.overlayDim
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    dismiss()
                }

            if showDetail {
                detailCard
            } else {
                collapsedCard
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            isPresented = false
            showDetail = false
            dragOffset = 0
        }
    }

    private var collapsedCard: some View {
        VStack(spacing: 0) {
            heroArtwork(isDetail: false)
                .frame(height: 360)

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
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            showDetail = true
                        }
                    } label: {
                        Label("Explore", systemImage: "chevron.right")
                    }
                    .buttonStyle(BreezyPrimaryButtonStyle())
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BreezyTheme.todayFeatureDetailCard)
        }
        .frame(maxWidth: 560)
        .matchedGeometryEffect(id: "today.card.shell", in: todayCardNamespace)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.22), radius: 28, y: 18)
        .padding(.horizontal, 20)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BreezyTheme.todayFeatureCloseIcon)
                    .frame(width: 30, height: 30)
                    .background(BreezyTheme.todayFeatureCloseBackground, in: Circle())
            }
            .padding(14)
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    let predicted = value.predictedEndTranslation.height
                    if value.translation.height > 130 || predicted > 190 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.96).combined(with: .opacity),
                removal: .scale(scale: 0.98).combined(with: .opacity)
            )
        )
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            heroArtwork(isDetail: true)
                .frame(height: 360)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Create with App Store-inspired calm.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(BreezyTheme.textPrimary)

                    Text("Breezy Diary keeps your entries fully offline while offering a playful writing feel. Use time and weather controls, pick location source, and maintain your own private moment log with smooth card interactions.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(BreezyTheme.textSecondary)
                        .lineSpacing(3)

                    Label("Edit and delete entries anytime", systemImage: "square.and.pencil")
                    Label("Windy ambient animation with subtle motion", systemImage: "wind")
                    Label("No account and no network required", systemImage: "lock.shield")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BreezyTheme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 270)
            .background(BreezyTheme.todayFeatureDetailBackground)

            HStack {
                Button("Back") {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        showDetail = false
                    }
                }
                .buttonStyle(BreezyPillButtonStyle(accent: BreezyTheme.softBlue))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                        isPresented = false
                    }
                    onStartWriting()
                } label: {
                    Label("Start Writing", systemImage: "sparkles")
                }
                .buttonStyle(BreezyPrimaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(BreezyTheme.todayFeatureDetailCard)
        }
        .frame(maxWidth: 700)
        .background(BreezyTheme.todayFeatureDetailCard)
        .matchedGeometryEffect(id: "today.card.shell", in: todayCardNamespace)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(BreezyTheme.todayFeatureDetailStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 30, y: 18)
        .padding(.horizontal, 14)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BreezyTheme.todayFeatureCloseIcon)
                    .frame(width: 30, height: 30)
                    .background(BreezyTheme.todayFeatureCloseBackground, in: Circle())
            }
            .padding(14)
        }
        .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
    }

    private func heroArtwork(isDetail: Bool) -> some View {
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

            // Illustration-like layers to mimic App Store Today hero art.
            Circle()
                .fill(.white.opacity(0.35))
                .frame(width: 260, height: 260)
                .offset(x: 230, y: -55)
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 190, height: 190)
                .offset(x: 165, y: 120)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.55))
                .frame(width: 130, height: 18)
                .offset(x: 34, y: 245)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.45))
                .frame(width: 95, height: 14)
                .offset(x: 56, y: 272)

            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BreezyTheme.todayCardTextOnImage.opacity(0.92))
                Text("Breezy Diary")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(BreezyTheme.todayCardTextOnImage)
                Text("A calm, playful place for your daily stories.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(BreezyTheme.todayCardTextOnImage.opacity(0.9))
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
        }
        .matchedGeometryEffect(id: "today.card.hero", in: todayCardNamespace)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.56), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            if !isDetail {
                Text("Swipe down to close")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BreezyTheme.todayCardTextOnImage.opacity(0.88))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.14), in: Capsule())
                    .padding(.leading, 18)
                    .padding(.bottom, 16)
            }
        }
    }
}
