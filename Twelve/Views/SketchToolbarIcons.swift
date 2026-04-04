import SwiftUI

/// Loose, hand-drawn–style line icons (unified stroke, no boxes).
enum SketchToolbarIcons {
    static let strokeColor = TwelveTheme.primaryBlue
    static let lineWidth: CGFloat = 2.35
    static let style: StrokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
}

struct SketchCalendarIcon: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let inset: CGFloat = 1.2
            var bodyPath = Path()
            bodyPath.addRoundedRect(
                in: CGRect(x: inset + 0.4, y: inset + h * 0.22, width: w - 2 * inset - 0.8, height: h * 0.72 - inset),
                cornerSize: CGSize(width: 3.2, height: 3.2),
                style: .continuous
            )
            context.stroke(bodyPath, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var hookL = Path()
            hookL.move(to: CGPoint(x: w * 0.30, y: h * 0.14))
            hookL.addQuadCurve(to: CGPoint(x: w * 0.30, y: h * 0.22), control: CGPoint(x: w * 0.22, y: h * 0.17))
            context.stroke(hookL, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var hookR = Path()
            hookR.move(to: CGPoint(x: w * 0.70, y: h * 0.14))
            hookR.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.22), control: CGPoint(x: w * 0.78, y: h * 0.17))
            context.stroke(hookR, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var spiral = Path()
            spiral.move(to: CGPoint(x: w * 0.18, y: h * 0.36))
            spiral.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.38), control: CGPoint(x: w * 0.5, y: h * 0.32))
            context.stroke(spiral, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var dash = Path()
            dash.move(to: CGPoint(x: w * 0.22, y: h * 0.52))
            dash.addLine(to: CGPoint(x: w * 0.78, y: h * 0.54))
            context.stroke(dash, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)
        }
        .frame(width: size, height: size)
    }
}

struct SketchPaletteIcon: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            var blob = Path()
            blob.move(to: CGPoint(x: w * 0.52, y: h * 0.12))
            blob.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.42), control: CGPoint(x: w * 0.82, y: h * 0.18))
            blob.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.82), control: CGPoint(x: w * 0.94, y: h * 0.62))
            blob.addQuadCurve(to: CGPoint(x: w * 0.28, y: h * 0.88), control: CGPoint(x: w * 0.55, y: h * 0.94))
            blob.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.48), control: CGPoint(x: w * 0.06, y: h * 0.76))
            blob.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.12), control: CGPoint(x: w * 0.18, y: h * 0.22))
            context.stroke(blob, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            let dots: [(CGFloat, CGFloat, Color)] = [
                (0.38, 0.38, TwelveTheme.accentYellow),
                (0.58, 0.32, TwelveTheme.softBlue),
                (0.48, 0.58, TwelveTheme.primaryBlueDark)
            ]
            for (px, py, c) in dots {
                var d = Path()
                d.addEllipse(in: CGRect(x: w * px - 2.8, y: h * py - 2.8, width: 5.6, height: 5.6))
                context.fill(d, with: .color(c))
                context.stroke(d, with: .color(SketchToolbarIcons.strokeColor.opacity(0.35)), lineWidth: 0.6)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Circle + up-arrow sketch (scroll to top), matches other toolbar line icons.
struct SketchScrollToTopIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2
            let cy = h * 0.48
            let r = min(w, h) * 0.38

            var ring = Path()
            ring.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
            context.stroke(ring, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var shaft = Path()
            shaft.move(to: CGPoint(x: cx + 0.3, y: cy + r * 0.15))
            shaft.addQuadCurve(to: CGPoint(x: cx - 0.2, y: cy - r * 0.55), control: CGPoint(x: cx + 1.0, y: cy - r * 0.22))
            context.stroke(shaft, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var headL = Path()
            headL.move(to: CGPoint(x: cx - r * 0.42, y: cy - r * 0.38))
            headL.addQuadCurve(to: CGPoint(x: cx, y: cy - r * 0.72), control: CGPoint(x: cx - r * 0.38, y: cy - r * 0.58))
            context.stroke(headL, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var headR = Path()
            headR.move(to: CGPoint(x: cx + r * 0.42, y: cy - r * 0.38))
            headR.addQuadCurve(to: CGPoint(x: cx, y: cy - r * 0.72), control: CGPoint(x: cx + r * 0.38, y: cy - r * 0.58))
            context.stroke(headR, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)
        }
        .frame(width: size, height: size)
    }
}

/// Hand-drawn cog (settings), loose strokes to match calendar / palette.
struct SketchGearIcon: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2
            let cy = h / 2
            let n = 6
            let rTip = min(w, h) * 0.40
            let rValley = min(w, h) * 0.26
            var gear = Path()
            for i in 0..<n {
                let a0 = CGFloat(i) / CGFloat(n) * 2 * .pi - .pi / 2
                let a1 = a0 + .pi / CGFloat(n) * 0.38
                let a2 = a0 + .pi / CGFloat(n) * 0.62
                let a3 = a0 + .pi / CGFloat(n)
                let p0 = CGPoint(x: cx + cos(a0) * rValley, y: cy + sin(a0) * rValley)
                let p1 = CGPoint(x: cx + cos(a1) * rTip, y: cy + sin(a1) * rTip)
                let p2 = CGPoint(x: cx + cos(a2) * rTip, y: cy + sin(a2) * rTip)
                let p3 = CGPoint(x: cx + cos(a3) * rValley, y: cy + sin(a3) * rValley)
                if i == 0 {
                    gear.move(to: p0)
                } else {
                    gear.addLine(to: p0)
                }
                gear.addQuadCurve(to: p2, control: p1)
                gear.addQuadCurve(to: p3, control: CGPoint(x: (p2.x + p3.x) / 2 + 0.4, y: (p2.y + p3.y) / 2))
            }
            gear.closeSubpath()
            context.stroke(gear, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            let rHub = min(w, h) * 0.15
            var hub = Path()
            hub.addEllipse(in: CGRect(x: cx - rHub, y: cy - rHub, width: rHub * 2, height: rHub * 2))
            context.stroke(hub, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)
        }
        .frame(width: size, height: size)
    }
}

/// Hand-drawn magnifying glass for search.
struct SketchSearchIcon: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w * 0.38
            let cy = h * 0.38
            let lensR = min(w, h) * 0.26

            var ring = Path()
            ring.addEllipse(in: CGRect(x: cx - lensR, y: cy - lensR, width: lensR * 2, height: lensR * 2))
            context.stroke(ring, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)

            var handle = Path()
            handle.move(to: CGPoint(x: cx + lensR * 0.65, y: cy + lensR * 0.72))
            handle.addQuadCurve(
                to: CGPoint(x: w * 0.88, y: h * 0.90),
                control: CGPoint(x: cx + lensR * 1.35, y: cy + lensR * 1.05)
            )
            context.stroke(handle, with: .color(SketchToolbarIcons.strokeColor), style: SketchToolbarIcons.style)
        }
        .frame(width: size, height: size)
    }
}

struct SketchPlusIcon: View {
    var size: CGFloat = 28
    var color: Color = .white
    var lineWidth: CGFloat = 3.1

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2
            let cy = h / 2
            let arm: CGFloat = min(w, h) * 0.32
            var v = Path()
            v.move(to: CGPoint(x: cx - 0.6, y: cy - arm))
            v.addQuadCurve(to: CGPoint(x: cx + 0.4, y: cy + arm), control: CGPoint(x: cx + 1.2, y: cy))
            context.stroke(v, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            var hz = Path()
            hz.move(to: CGPoint(x: cx - arm, y: cy + 0.3))
            hz.addQuadCurve(to: CGPoint(x: cx + arm, y: cy - 0.2), control: CGPoint(x: cx, y: cy + 1.0))
            context.stroke(hz, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
