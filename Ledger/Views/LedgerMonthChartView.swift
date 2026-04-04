import Charts
import SwiftUI

struct LedgerChartMonthPoint: Identifiable {
    let id: Int
    /// Axis label (month, optional year when span is long).
    let label: String
    let net: Decimal
}

struct LedgerMonthChartView: View {
    let points: [LedgerChartMonthPoint]
    let formatMoney: (Decimal) -> String

    /// Horizontal space per month so bars stay readable when scrolling.
    private let monthColumnWidth: CGFloat = 44

    private var chartContentWidth: CGFloat {
        let n = max(points.count, 1)
        return CGFloat(n) * monthColumnWidth
    }

    private var xAxisIndices: [Int] {
        guard !points.isEmpty else { return [] }
        let last = points.count - 1
        if last <= 0 { return [0] }
        // One label every month for moderate counts; thin out if huge.
        let strideBy: Int
        if last <= 18 { strideBy = 1 }
        else if last <= 36 { strideBy = 2 }
        else { strideBy = 3 }
        var out: [Int] = []
        var i = 0
        while i <= last {
            out.append(i)
            i += strideBy
        }
        if out.last != last { out.append(last) }
        return out
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
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
            .chartXScale(domain: -0.5...(Double(points.map(\.id).max() ?? 0) + 0.5))
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
                                .font(TwelveTheme.appFont(size: 9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
            }
            .frame(width: chartContentWidth, height: 220)
        }
        .frame(height: 220)
    }
}

enum LedgerChartData {
    private static let maxMonthsBack = 72

    /// One row per calendar month from oldest relevant month through current month (cap 72 months).
    static func monthlyNetSeries(bookId: String, entries: [LedgerEntry]) -> [LedgerChartMonthPoint] {
        let cal = Calendar.current
        let now = Date()
        let bookFiltered = entries.filter { $0.bookId == bookId }
        guard !bookFiltered.isEmpty else { return [] }

        func startOfMonth(_ d: Date) -> Date {
            cal.date(from: cal.dateComponents([.year, .month], from: d)) ?? d
        }

        guard let endMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return [] }
        guard let earliestAllowed = cal.date(byAdding: .month, value: -(maxMonthsBack - 1), to: endMonth) else { return [] }

        let oldestDate = bookFiltered.map(\.date).min() ?? now
        let oldestMonth = startOfMonth(oldestDate)
        let cappedStart = max(oldestMonth, earliestAllowed)

        guard let twelveBack = cal.date(byAdding: .month, value: -11, to: endMonth) else { return [] }
        let rangeStart = min(cappedStart, twelveBack)

        var monthCursor = rangeStart
        var result: [LedgerChartMonthPoint] = []
        var index = 0
        let showYearInLabel: Bool = {
            var n = 0
            var d = rangeStart
            while d <= endMonth {
                n += 1
                guard let nx = cal.date(byAdding: .month, value: 1, to: d) else { break }
                d = nx
            }
            return n >= 12
        }()

        while monthCursor <= endMonth {
            let y = cal.component(.year, from: monthCursor)
            let m = cal.component(.month, from: monthCursor)
            var net: Decimal = 0
            for e in bookFiltered {
                let ey = cal.component(.year, from: e.date)
                let em = cal.component(.month, from: e.date)
                guard ey == y, em == m else { continue }
                net += e.signedNetAmount
            }
            let label: String
            if showYearInLabel {
                label = monthCursor.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
            } else {
                label = monthCursor.formatted(.dateTime.month(.abbreviated))
            }
            result.append(LedgerChartMonthPoint(id: index, label: label, net: LedgerDecimalFormatting.round(net)))
            index += 1
            guard let next = cal.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = next
        }
        return result
    }
}
