import SwiftUI
import UIKit

struct LedgerAddTransactionSheet: View {
    enum Mode {
        case create
        case edit(LedgerEntry)
    }

    @Binding var isPresented: Bool
    let mode: Mode
    var onSave: (LedgerEntry) -> Void

    @State private var transactionDate: Date = Date()
    @State private var kind: LedgerTransactionKind = .expense
    @State private var amountText: String = ""
    @State private var refundText: String = ""
    @State private var category: String = ""
    @State private var note: String = ""
    @State private var locationText: String = ""

    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showMapPicker = false
    @State private var datePickerDraftDate: Date = Date()
    @State private var datePickerDisplayedMonthStart: Date = LedgerAddTransactionSheet.monthAnchor(for: Date())
    @State private var timePickerDraftDate: Date = Date()

    @FocusState private var amountFocused: Bool
    @FocusState private var refundFocused: Bool
    @FocusState private var categoryFocused: Bool
    @FocusState private var noteFocused: Bool

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private var parsedAmount: Decimal? {
        LedgerDecimalFormatting.parseAmount(from: amountText)
    }

    private var parsedRefund: Decimal? {
        LedgerDecimalFormatting.parseAmount(from: refundText)
    }

    private var canSave: Bool {
        guard let a = parsedAmount, a > 0 else { return false }
        guard !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if let r = parsedRefund, r > 0 {
            return r <= a
        }
        return true
    }

    private var sheetTitle: String {
        switch mode {
        case .create: return "New entry"
        case .edit: return "Edit entry"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    kindRow

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 20, weight: .semibold))
                            .focused($amountFocused)
                            .onChange(of: amountText) { _, new in
                                let s = LedgerDecimalFormatting.sanitizeAmountInput(new)
                                if s != new { amountText = s }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if case .edit = mode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Refund (optional)")
                                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                                .foregroundStyle(TwelveTheme.textSecondary)
                            TextField("0.00", text: $refundText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .font(TwelveTheme.appFont(size: 16, weight: .medium))
                                .focused($refundFocused)
                                .onChange(of: refundText) { _, new in
                                    let s = LedgerDecimalFormatting.sanitizeAmountInput(new)
                                    if s != new { refundText = s }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text("Reduces this line only (e.g. expense 100, refund 20 → net 80).")
                                .font(TwelveTheme.appFont(size: 11))
                                .foregroundStyle(TwelveTheme.textTertiary)
                        }
                    }

                    dateTimeRow

                    locationSection

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("e.g. Food, Transport", text: $category)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 16))
                            .focused($categoryFocused)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        TextField("Optional", text: $note)
                            .textFieldStyle(.plain)
                            .font(TwelveTheme.appFont(size: 15))
                            .focused($noteFocused)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(18)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(sheetTitle)
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .disabled(!canSave)
                }
            }
            .onAppear { configureFromMode() }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showTimePicker) {
                timePickerSheet
            }
            .sheet(isPresented: $showMapPicker) {
                ComposerLocationPickerSheet(
                    onPickAddress: { locationText = $0 },
                    onClearAddress: { locationText = "" }
                )
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .font(TwelveTheme.appFont(size: 16))
    }

    private var kindRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Type")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 6)
            HStack(spacing: 6) {
                kindPill(.expense)
                kindPill(.income)
            }
        }
    }

    private func kindPill(_ k: LedgerTransactionKind) -> some View {
        let on = kind == k
        return Button {
            dismissKeyboard()
            kind = k
        } label: {
            Text(k.title)
                .font(TwelveTheme.appFont(size: 13, weight: .semibold))
                .foregroundStyle(on ? Color.white : TwelveTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        on
                            ? LinearGradient(
                                colors: [TwelveTheme.primaryBlue, TwelveTheme.primaryBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [TwelveTheme.secondarySurface, TwelveTheme.secondarySurface], startPoint: .top, endPoint: .bottom)
                    )
                )
                .overlay(Capsule().stroke(on ? Color.clear : TwelveTheme.strokeSoft, lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(TwelveTheme.textSecondary)
                Text(locationText.isEmpty ? "No address selected" : locationText)
                    .font(TwelveTheme.appFont(size: 13))
                    .foregroundStyle(locationText.isEmpty ? TwelveTheme.textTertiary : TwelveTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Pick on Map") {
                dismissKeyboard()
                showMapPicker = true
            }
            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
        }
    }

    private var dateTimeRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Date & Time")
                .font(TwelveTheme.appFont(size: 13, weight: .medium))
                .foregroundStyle(TwelveTheme.textSecondary)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 6)
            Button {
                dismissKeyboard()
                let cal = Calendar.current
                let start = cal.startOfDay(for: transactionDate)
                datePickerDraftDate = start
                datePickerDisplayedMonthStart = Self.monthAnchor(for: start)
                showDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(dateFormatter.string(from: transactionDate))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .font(TwelveTheme.appFont(size: 14, weight: .medium))
                .foregroundStyle(TwelveTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
            Button {
                dismissKeyboard()
                timePickerDraftDate = transactionDate
                showTimePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text(timeFormatter.string(from: transactionDate))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .font(TwelveTheme.appFont(size: 14, weight: .medium))
                .foregroundStyle(TwelveTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
            Button("Now") {
                transactionDate = Date()
                dismissKeyboard()
            }
            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            ScrollView {
                CartoonMonthCalendar(
                    selectedDay: Binding(
                        get: { Calendar.current.startOfDay(for: datePickerDraftDate) },
                        set: { datePickerDraftDate = $0 }
                    ),
                    displayedMonthStart: $datePickerDisplayedMonthStart,
                    entryDates: []
                )
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollBounceBehavior(.basedOnSize)
            .padding(.horizontal, 18)
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TwelveTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Choose Date")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showDatePicker = false }
                        .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let calendar = Calendar.current
                        let dateParts = calendar.dateComponents([.year, .month, .day], from: datePickerDraftDate)
                        let timeParts = calendar.dateComponents([.hour, .minute], from: transactionDate)
                        var merged = DateComponents()
                        merged.year = dateParts.year
                        merged.month = dateParts.month
                        merged.day = dateParts.day
                        merged.hour = timeParts.hour
                        merged.minute = timeParts.minute
                        if let updated = calendar.date(from: merged) {
                            transactionDate = updated
                        }
                        showDatePicker = false
                    }
                    .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                }
            }
        }
        .font(TwelveTheme.appFont(size: 16))
        .presentationDetents([.height(580), .large])
        .presentationDragIndicator(.visible)
    }

    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                TwelveTheme.background
                    .ignoresSafeArea()
                TwelveAppWheelDatePicker(
                    selection: $timePickerDraftDate,
                    mode: .time,
                    minuteInterval: 1
                )
                .frame(maxWidth: .infinity)
                .frame(height: 232)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TwelveTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Choose Time")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showTimePicker = false }
                        .font(TwelveTheme.appFont(size: 17))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.hour, .minute], from: timePickerDraftDate)
                        if let updated = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: transactionDate) {
                            transactionDate = updated
                        }
                        showTimePicker = false
                    }
                    .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                }
            }
        }
        .font(TwelveTheme.appFont(size: 16))
        .presentationDetents([.height(320), .fraction(0.4)])
        .presentationDragIndicator(.visible)
    }

    private func configureFromMode() {
        switch mode {
        case .create:
            transactionDate = Date()
            kind = .expense
            amountText = ""
            refundText = ""
            category = ""
            note = ""
            locationText = ""
        case .edit(let entry):
            transactionDate = entry.date
            kind = entry.kind
            amountText = LedgerDecimalFormatting.displayString(for: entry.amount)
            refundText = entry.refundTotal > 0 ? LedgerDecimalFormatting.displayString(for: entry.refundTotal) : ""
            category = entry.category
            note = entry.note
            locationText = entry.location ?? ""
        }
    }

    private static func monthAnchor(for date: Date) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let c = cal.dateComponents([.year, .month], from: day)
        return cal.date(from: c) ?? day
    }

    private func save() {
        guard let a = parsedAmount, a > 0 else { return }
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cat.isEmpty else { return }
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let loc = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
        let refundPortion: Decimal
        if case .edit = mode, let r = parsedRefund, r > 0 {
            refundPortion = min(LedgerDecimalFormatting.round(r), a)
        } else {
            refundPortion = 0
        }
        let id: UUID
        switch mode {
        case .create:
            id = UUID()
        case .edit(let entry):
            id = entry.id
        }
        let entry = LedgerEntry(
            id: id,
            date: transactionDate,
            amount: a,
            kind: kind,
            refundTotal: refundPortion,
            category: cat,
            note: n,
            location: loc.isEmpty ? nil : loc
        )
        onSave(entry)
        isPresented = false
    }

    private func dismissKeyboard() {
        amountFocused = false
        refundFocused = false
        categoryFocused = false
        noteFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
