import Charts
import SwiftUI

struct LedgerMonthChartView: View {
    /// Last 12 months, oldest first (label + signed net).
    let points: [(label: String, net: Decimal)]
    let formatMoney: (Decimal) -> String

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                BarMark(
                    x: .value("Month", p.label),
                    y: .value("Net", Double(truncating: p.net as NSDecimalNumber))
                )
                .foregroundStyle((p.net as NSDecimalNumber).doubleValue >= 0 ? TwelveTheme.primaryBlue : TwelveTheme.primaryBlueDark)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let d = v.as(Double.self) {
                        Text(formatMoney(Decimal(d)))
                            .font(TwelveTheme.appFont(size: 9))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { v in
                AxisValueLabel {
                    if let s = v.as(String.self) {
                        Text(s)
                            .font(TwelveTheme.appFont(size: 9))
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

enum LedgerChartData {
    static func last12MonthsNet(bookId: String, entries: [LedgerEntry]) -> [(String, Decimal)] {
        let cal = Calendar.current
        let now = Date()
        var result: [(String, Decimal)] = []
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
            let label = String(format: "%d-%02d", y, m)
            result.append((label, LedgerDecimalFormatting.round(net)))
        }
        return result
    }
}
