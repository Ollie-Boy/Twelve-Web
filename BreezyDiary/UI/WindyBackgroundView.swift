import SwiftUI

struct WindyBackgroundView: View {
    private let cloudConfigs: [CloudConfig] = [
        .init(size: 80, yRatio: 0.16, speed: 24, opacity: 0.15),
        .init(size: 58, yRatio: 0.30, speed: 31, opacity: 0.13),
        .init(size: 96, yRatio: 0.48, speed: 28, opacity: 0.12),
        .init(size: 64, yRatio: 0.67, speed: 35, opacity: 0.14)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 40.0)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    LinearGradient(
                        colors: [
                            BreezyTheme.backgroundTop,
                            BreezyTheme.backgroundBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    ForEach(Array(cloudConfigs.enumerated()), id: \.offset) { index, cloud in
                        let phase = (time / cloud.speed).truncatingRemainder(dividingBy: 1.0)
                        let x = CGFloat(phase) * (size.width + cloud.size + 80) - cloud.size - 40
                        let yBase = size.height * cloud.yRatio
                        let y = yBase + CGFloat(sin(time * 0.6 + Double(index) * 0.9) * 7)

                        Image(systemName: "cloud.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: cloud.size, height: cloud.size * 0.62)
                            .foregroundStyle(BreezyTheme.cloudTint.opacity(cloud.opacity))
                            .position(x: x, y: y)
                    }

                    ForEach(0..<4, id: \.self) { i in
                        Capsule(style: .continuous)
                            .fill(BreezyTheme.windLine.opacity(0.16))
                            .frame(width: 110, height: 3.5)
                            .offset(
                                x: CGFloat(sin(time * 0.45 + Double(i) * 1.3) * 18),
                                y: size.height * (0.24 + CGFloat(i) * 0.17)
                            )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CloudConfig {
    let size: CGFloat
    let yRatio: CGFloat
    let speed: Double
    let opacity: Double
}
