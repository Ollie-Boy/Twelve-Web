import SwiftUI

private struct DetailHeroOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TodayFeatureCardOverlay: View {
    @Binding var isPresented: Bool
    var onStartWriting: () -> Void = {}
    @State private var dragOffset: CGFloat = 0
    @State private var showDetail: Bool = false
    @State private var detailHeroOffset: CGFloat = 0
    @State private var detailBackOffset: CGFloat = 0
    @Namespace private var todayCardNamespace

    var body: some View {
        ZStack {
            TwelveTheme.overlayDim
                .opacity(1 - Double(interactionProgress * 0.35))
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
        .animation(.spring(response: 0.46, dampingFraction: 0.88), value: showDetail)
    }

    private var verticalDismissProgress: CGFloat {
        min(max(dragOffset / 220, 0), 1)
    }

    private var horizontalBackProgress: CGFloat {
        min(max(detailBackOffset / 280, 0), 1)
    }

    private var interactionProgress: CGFloat {
        max(verticalDismissProgress, horizontalBackProgress)
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            isPresented = false
            showDetail = false
            dragOffset = 0
            detailBackOffset = 0
        }
    }

    private func goBackFromDetail() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            detailBackOffset = 0
            showDetail = false
        }
    }

    private var collapsedCard: some View {
        VStack(spacing: 0) {
            heroArtwork(isDetail: false)
                .frame(height: 360)
                .matchedGeometryEffect(id: "today.hero.container", in: todayCardNamespace)

            VStack(alignment: .leading, spacing: 14) {
                Text("Offline. Private. Playful.")
                    .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textPrimary)
                    .matchedGeometryEffect(id: "today.body.title", in: todayCardNamespace)

                Text("Write with animated text feel, adjust date and weather, and save everything locally on your iPhone.")
                    .font(TwelveTheme.appFont(size: 15))
                    .foregroundStyle(TwelveTheme.textSecondary)
                    .lineSpacing(3)
                    .matchedGeometryEffect(id: "today.body.subtitle", in: todayCardNamespace)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Not now")
                            .font(TwelveTheme.appFont(size: 15, weight: .medium))
                    }
                    .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            detailBackOffset = 0
                            showDetail = true
                        }
                    } label: {
                        Label("Explore", systemImage: "chevron.right")
                    }
                    .buttonStyle(TwelvePrimaryButtonStyle())
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TwelveTheme.todayFeatureDetailCard)
            .matchedGeometryEffect(id: "today.body.container", in: todayCardNamespace)
        }
        .frame(maxWidth: 560)
        .matchedGeometryEffect(id: "today.card.shell", in: todayCardNamespace)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: TwelveTheme.modalCardShadow, radius: 28, y: 18)
        .padding(.horizontal, 20)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(TwelveTheme.appFont(size: 14, weight: .semibold))
                    .foregroundStyle(TwelveTheme.todayFeatureCloseIcon)
                    .frame(width: 30, height: 30)
                    .background(TwelveTheme.todayFeatureCloseBackground, in: Circle())
                    .matchedGeometryEffect(id: "today.close.button", in: todayCardNamespace)
            }
            .opacity(1 - Double(verticalDismissProgress * 0.6))
            .padding(14)
        }
        .offset(y: dragOffset)
        .gesture(dismissDragGesture)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.96).combined(with: .opacity),
                removal: .scale(scale: 0.98).combined(with: .opacity)
            )
        )
    }

    private var detailCard: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let bottomInset = proxy.safeAreaInsets.bottom
            let collapseWidth = min(560, proxy.size.width - 40)
            let collapseHeight = min(700, proxy.size.height - 120)
            let width = proxy.size.width - (proxy.size.width - collapseWidth) * horizontalBackProgress
            let height = proxy.size.height - (proxy.size.height - collapseHeight) * horizontalBackProgress
            let cornerRadius = 4 + (horizontalBackProgress * 28)
            let xOffset = detailBackOffset * (0.86 - 0.22 * horizontalBackProgress)
            let yOffset = dragOffset - (horizontalBackProgress * 20)

            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                detailHeroParallax
                                detailContent
                            }
                        }
                        .coordinateSpace(name: "todayDetailScroll")
                        .onPreferenceChange(DetailHeroOffsetKey.self) { detailHeroOffset = $0 }

                        detailStickyHeader
                            .padding(.top, topInset)
                    }

                    detailFooter
                        .padding(.bottom, max(bottomInset, 12))
                }
                .frame(width: width, height: height)
                .background(TwelveTheme.todayFeatureDetailCard)
                .matchedGeometryEffect(id: "today.card.shell", in: todayCardNamespace)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(TwelveTheme.todayFeatureDetailStroke.opacity(0.7), lineWidth: 0.6)
                )
                .shadow(
                    color: Color.black.opacity(0.10 + Double(horizontalBackProgress) * 0.16),
                    radius: 8 + horizontalBackProgress * 18,
                    y: 6 + horizontalBackProgress * 10
                )
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .offset(x: xOffset, y: yOffset)
                .scaleEffect(1 - (horizontalBackProgress * 0.04))
                .opacity(1 - Double(horizontalBackProgress * 0.1))
                .gesture(dismissDragGesture)
                .simultaneousGesture(detailBackSwipeGesture)
                .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(TwelveTheme.appFont(size: 14, weight: .semibold))
                        .foregroundStyle(TwelveTheme.todayFeatureCloseIcon)
                        .frame(width: 32, height: 32)
                        .background(TwelveTheme.todayFeatureCloseBackground, in: Circle())
                        .matchedGeometryEffect(id: "today.close.button", in: todayCardNamespace)
                }
                .opacity(1 - Double(interactionProgress * 0.7))
                .padding(.top, topInset + 8)
                .padding(.trailing, 16)
            }
            .ignoresSafeArea()
        }
    }

    private var detailHeroParallax: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("todayDetailScroll")).minY
            let stretch = max(0, minY)
            let parallax = minY < 0 ? -minY * 0.18 : 0

            heroArtwork(isDetail: true)
                .frame(height: 410 + stretch)
                .offset(y: minY > 0 ? -minY : parallax)
                .preference(key: DetailHeroOffsetKey.self, value: minY)
                .matchedGeometryEffect(id: "today.hero.container", in: todayCardNamespace)
        }
        .frame(height: 410)
    }

    private var detailContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Create with App Store-inspired calm.")
                    .font(TwelveTheme.appFont(size: 30, weight: .bold))
                    .foregroundStyle(TwelveTheme.textPrimary)

                Text("Twelve keeps your entries fully offline while offering a playful writing feel. Use time and weather controls, pick location source, and maintain your own private moment log with smooth card interactions.")
                    .font(TwelveTheme.appFont(size: 16))
                    .foregroundStyle(TwelveTheme.textSecondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TwelveTheme.todayFeatureDetailCard)
            .matchedGeometryEffect(id: "today.body.container", in: todayCardNamespace)

            VStack(alignment: .leading, spacing: 14) {
                Label("Edit and delete entries anytime", systemImage: "square.and.pencil")
                Label("Windy ambient animation with subtle motion", systemImage: "wind")
                Label("No account and no network required", systemImage: "lock.shield")
            }
            .font(TwelveTheme.appFont(size: 15, weight: .medium))
            .foregroundStyle(TwelveTheme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TwelveTheme.todayFeatureDetailBackground)
        }
    }

    private var detailFooter: some View {
        HStack {
            Button("Back") {
                goBackFromDetail()
            }
            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))

            Spacer()

            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                    detailBackOffset = 0
                    isPresented = false
                }
                onStartWriting()
            } label: {
                Label("Start Writing", systemImage: "sparkles")
            }
            .buttonStyle(TwelvePrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(TwelveTheme.todayFeatureDetailCard)
    }

    private var detailStickyHeader: some View {
        let progress = min(max((-detailHeroOffset - 90) / 70, 0), 1)
        let gestureFade = max(0, 1 - interactionProgress * 0.9)
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("TODAY")
                    .font(TwelveTheme.appFont(size: 11, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textSecondary)
                Text("Twelve")
                    .font(TwelveTheme.handwrittenFont(size: 22))
                    .foregroundStyle(TwelveTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)

            Rectangle()
                .fill(TwelveTheme.todayFeatureDetailStroke)
                .frame(height: 0.6)
        }
        .opacity(progress * gestureFade)
        .offset(x: detailBackOffset * 0.08, y: dragOffset * 0.05)
        .allowsHitTesting(false)
    }

    private func heroArtwork(isDetail: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    TwelveTheme.todayCardBlueStart,
                    TwelveTheme.todayCardBlueEnd,
                    TwelveTheme.todayCardYellow
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    TwelveTheme.todayFeatureScrim.opacity(isDetail ? 0.44 : 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Illustration-like layers to mimic App Store Today hero art.
            Circle()
                .fill(TwelveTheme.heroOrbPrimary)
                .frame(width: 260, height: 260)
                .offset(x: 230, y: -55)
            Circle()
                .fill(TwelveTheme.heroOrbSecondary)
                .frame(width: 190, height: 190)
                .offset(x: 165, y: 120)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TwelveTheme.heroBarWide)
                .frame(width: 130, height: 18)
                .offset(x: 34, y: 245)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TwelveTheme.heroBarNarrow)
                .frame(width: 95, height: 14)
                .offset(x: 56, y: 272)

            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY")
                    .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                    .foregroundStyle(TwelveTheme.todayCardTextOnImage.opacity(0.92))
                    .matchedGeometryEffect(id: "today.hero.kicker", in: todayCardNamespace)
                Text("Twelve")
                    .font(TwelveTheme.handwrittenFont(size: 46))
                    .foregroundStyle(TwelveTheme.todayCardTextOnImage)
                    .matchedGeometryEffect(id: "today.hero.title", in: todayCardNamespace)
                Text("A calm, playful place for your daily stories.")
                    .font(TwelveTheme.appFont(size: 17))
                    .foregroundStyle(TwelveTheme.todayCardTextOnImage.opacity(0.9))
                    .lineSpacing(3)
                    .matchedGeometryEffect(id: "today.hero.subtitle", in: todayCardNamespace)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
        }
        .matchedGeometryEffect(id: "today.card.hero", in: todayCardNamespace)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(TwelveTheme.heroCardStroke, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            if !isDetail {
                Text("Swipe down to close")
                    .font(TwelveTheme.appFont(size: 12, weight: .medium))
                    .foregroundStyle(TwelveTheme.todayCardTextOnImage.opacity(0.88))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(TwelveTheme.heroSwipeHintBackground, in: Capsule())
                    .padding(.leading, 18)
                    .padding(.bottom, 16)
            }
        }
    }

    private var dismissDragGesture: some Gesture {
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
    }

    // Full-screen interactive back gesture (right swipe) in detail mode.
    private var detailBackSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard showDetail else { return }
                let x = value.translation.width
                let y = value.translation.height
                guard x > 0, abs(x) > abs(y) * 1.1 else { return }
                detailBackOffset = min(x, 340)
            }
            .onEnded { value in
                guard showDetail else { return }
                let x = value.translation.width
                let predicted = value.predictedEndTranslation.width
                if x > 120 || predicted > 190 {
                    goBackFromDetail()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        detailBackOffset = 0
                    }
                }
            }
    }
}
