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
