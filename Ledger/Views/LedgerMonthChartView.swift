import Charts
import SwiftUI

struct LedgerChartMonthPoint: Identifiable {
    let id: Int
    /// Short month label (e.g. Jan) for sparse axis ticks.
    let label: String
    let net: Decimal
}

struct LedgerMonthChartView: View {
    let points: [LedgerChartMonthPoint]
    let formatMoney: (Decimal) -> String

    /// Indices (into `points`) that get an x-axis label — sparse so labels stay readable.
    private var xAxisIndices: [Int] {
        guard !points.isEmpty else { return [] }
        let last = points.count - 1
        if last <= 0 { return [0] }
        let step = max(3, last / 4)
        var out: [Int] = [0]
        var i = step
        while i < last {
            out.append(i)
            i += step
        }
        if out.last != last { out.append(last) }
        return out
    }

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Month", p.id),
                    y: .value("Net", Double(truncating: p.net as NSDecimalNumber))
                )
                .foregroundStyle((p.net as NSDecimalNumber).doubleValue >= 0 ? TwelveTheme.primaryBlue : TwelveTheme.primaryBlueDark)
                .cornerRadius(4)
            }
        }
        .chartXScale(domain: -0.5...(Double(max(points.map(\.id).max() ?? 0)) + 0.5))
        .chartYAxis {
            AxisMarks(position: .leading) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let d = v.as(Double.self) {
                        Text(formatMoney(Decimal(d)))
                            .font(TwelveTheme.appFont(size: 10))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisIndices) { v in
                AxisValueLabel(centered: true) {
                    if let idx = v.as(Int.self),
                       let p = points.first(where: { $0.id == idx }) {
                        Text(p.label)
                            .font(TwelveTheme.appFont(size: 10))
                    }
                }
            }
        }
        .frame(height: 220)
    }
}

enum LedgerChartData {
    static func last12MonthsNet(bookId: String, entries: [LedgerEntry]) -> [LedgerChartMonthPoint] {
        let cal = Calendar.current
        let now = Date()
        var result: [LedgerChartMonthPoint] = []
        var index = 0
        for back in (0..<12).reversed() {
            guard let monthStart = cal.date(byAdding: .month, value: -back, to: now) else { continue }
            let y = cal.component(.year, from: monthStart)
            let m = cal.component(.month, from: monthStart)
            var net: Decimal = 0
            for e in entries where e.bookId == bookId {
                let ey = cal.component(.year, from: e.date)
                let em = cal.component(.month, from: e.date)
                guard ey == y, em == m else { continue }
                net += e.signedNetAmount
            }
            let label = monthStart.formatted(.dateTime.month(.abbreviated))
            result.append(LedgerChartMonthPoint(id: index, label: label, net: LedgerDecimalFormatting.round(net)))
            index += 1
        }
        return result
    }
}
