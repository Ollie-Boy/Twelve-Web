import SwiftUI

struct WindyBackgroundView: View {
    private let cloudConfigs: [CloudConfig] = [
        .init(size: 82, y: 110, speed: 17, opacity: 0.2),
        .init(size: 58, y: 220, speed: 24, opacity: 0.22),
        .init(size: 100, y: 340, speed: 19, opacity: 0.17),
        .init(size: 66, y: 500, speed: 26, opacity: 0.19),
        .init(size: 76, y: 660, speed: 21, opacity: 0.18)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
            GeometryReader { proxy in
                let width = proxy.size.width
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    ForEach(Array(cloudConfigs.enumerated()), id: \.offset) { index, cloud in
                        let base = CGFloat((time / cloud.speed).truncatingRemainder(dividingBy: 1))
                        let x = ((base * (width + cloud.size + 80)) - cloud.size - 40)
                        let yDrift = CGFloat(sin((time * 0.9) + Double(index) * 1.2)) * 8

                        Image(systemName: "cloud.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: cloud.size, height: cloud.size * 0.62)
                            .foregroundStyle(BreezyTheme.whiteCard.opacity(cloud.opacity))
                            .position(x: x, y: cloud.y + yDrift)
                    }

                    ForEach(0..<5, id: \.self) { i in
                        let y = CGFloat(160 + i * 130)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(BreezyTheme.whiteCard.opacity(0.12))
                            .frame(width: 120, height: 5)
                            .blur(radius: 0.7)
                            .offset(x: CGFloat(sin(time * 0.7 + Double(i)) * 26), y: y)
                    }
                }
                .drawingGroup()
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CloudConfig {
    let size: CGFloat
    let y: CGFloat
    let speed: Double
    let opacity: Double
}
