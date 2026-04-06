import Charts
import SwiftUI

struct LedgerChartMonthPoint: Identifiable {
    let id: Int
    /// Abbreviated month (Jan, Feb, …) for X-axis when same calendar year as previous point.
    let monthOnlyLabel: String
    let yearForMonth: Int
    let net: Decimal
}

struct LedgerMonthChartView: View {
    let points: [LedgerChartMonthPoint]
    let formatMoney: (Decimal) -> String

    /// Horizontal space per month so bars stay readable when scrolling.
    private let monthColumnWidth: CGFloat = 44
    /// Extra vertical room so top Y-axis currency labels are not clipped.
    private let chartPlotHeight: CGFloat = 200
    private let chartTopGutter: CGFloat = 14
    /// Fixed column for Y-axis labels (outside horizontal ScrollView so they stay visible).
    private let yAxisColumnWidth: CGFloat = 68

    private var chartContentWidth: CGFloat {
        let n = max(points.count, 1)
        return CGFloat(n) * monthColumnWidth
    }

    /// Shared Y domain so the fixed-axis chart and scrollable chart stay aligned.
    private var yScaleDomain: ClosedRange<Double> {
        guard !points.isEmpty else { return -1...1 }
        let vals = points.map { ($0.net as NSDecimalNumber).doubleValue }
        var lo = vals.min() ?? 0
        var hi = vals.max() ?? 0
        lo = min(lo, 0)
        hi = max(hi, 0)
        if lo == hi {
            return lo == 0 ? -1...1 : (lo - 1)...(hi + 1)
        }
        let span = hi - lo
        let pad = max(span * 0.06, 1)
        return (lo - pad)...(hi + pad)
    }

    /// Changes when series length or latest month data changes (re-scroll to trailing).
    private var chartScrollIdentity: String {
        guard let last = points.last else { return "empty" }
        return "\(points.count)-\(last.id)-\(last.net)-\(last.yearForMonth)-\(last.monthOnlyLabel)"
    }

    /// Month abbrev under X-axis; show full year on the first month of each calendar year (after the first point).
    private func xAxisDisplayLabel(at index: Int) -> String {
        guard index >= 0, index < points.count else { return "" }
        let p = points[index]
        if index == 0 { return p.monthOnlyLabel }
        let prev = points[index - 1]
        if prev.yearForMonth != p.yearForMonth {
            return String(p.yearForMonth)
        }
        return p.monthOnlyLabel
    }

    private var xAxisIndices: [Int] {
        guard !points.isEmpty else { return [] }
        let last = points.count - 1
        if last <= 0 { return [0] }
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

    private var chartTotalHeight: CGFloat { chartPlotHeight + chartTopGutter }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            yAxisOnlyChart
                .frame(width: yAxisColumnWidth, height: chartTotalHeight)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        scrollableChart
                            .frame(width: chartContentWidth, height: chartTotalHeight)
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id("ledgerChartTrailingAnchor")
                    }
                }
                .frame(height: chartTotalHeight)
                .onAppear { scrollChartToLatest(proxy: proxy) }
                .onChange(of: chartScrollIdentity) { _, _ in
                    scrollChartToLatest(proxy: proxy)
                }
            }
        }
        .frame(height: chartTotalHeight)
    }

    /// Y-axis labels only (invisible bars keep scale in sync with scrollable chart).
    private var yAxisOnlyChart: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Month", p.id),
                    y: .value("Net", Double(truncating: p.net as NSDecimalNumber))
                )
                .foregroundStyle(.clear)
                .cornerRadius(4)
            }
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: yScaleDomain)
        .chartYAxis {
            AxisMarks(position: .leading) { v in
                AxisGridLine()
                AxisValueLabel(anchor: .trailing) {
                    if let d = v.as(Double.self) {
                        Text(formatMoney(Decimal(d)))
                            .font(TwelveTheme.appFont(size: 10))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(.top, chartTopGutter)
    }

    private var scrollableChart: some View {
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
        .chartYScale(domain: yScaleDomain)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: xAxisIndices) { v in
                AxisValueLabel(centered: true) {
                    if let idx = v.as(Int.self),
                       points.contains(where: { $0.id == idx }) {
                        Text(xAxisDisplayLabel(at: idx))
                            .font(TwelveTheme.appFont(size: 9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.padding(.leading, 0)
        }
        .padding(.top, chartTopGutter)
    }

    private func scrollChartToLatest(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("ledgerChartTrailingAnchor", anchor: .trailing)
            }
        }
    }
}

enum LedgerChartData {
    private static let maxMonthsBack = 72

    /// One row per calendar month from oldest relevant month through current month (cap 72 months).
    static func monthlyNetSeries(bookId: String, entries: [LedgerEntry], signedNetForEntry: (LedgerEntry) -> Decimal = { $0.signedNetAmount }) -> [LedgerChartMonthPoint] {
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

        while monthCursor <= endMonth {
            let y = cal.component(.year, from: monthCursor)
            let m = cal.component(.month, from: monthCursor)
            var net: Decimal = 0
            for e in bookFiltered {
                let ey = cal.component(.year, from: e.date)
                let em = cal.component(.month, from: e.date)
                guard ey == y, em == m else { continue }
                net += signedNetForEntry(e)
            }
            let monthOnly = monthCursor.formatted(.dateTime.month(.abbreviated))
            result.append(
                LedgerChartMonthPoint(
                    id: index,
                    monthOnlyLabel: monthOnly,
                    yearForMonth: y,
                    net: LedgerDecimalFormatting.round(net)
                )
            )
            index += 1
            guard let next = cal.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = next
        }
        return result
    }
}
