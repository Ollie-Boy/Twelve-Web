import SwiftUI
import UIKit

/// Subclasses `UIDatePicker` so we re-apply fonts after the wheel builds or scrolls its rows.
final class TwelveStyledWheelDatePicker: UIDatePicker {
    override func layoutSubviews() {
        super.layoutSubviews()
        TwelveTheme.applyAppTypographyToWheelDatePicker(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        TwelveTheme.applyAppTypographyToWheelDatePicker(self)
        // Wheels sometimes materialize row labels after the first layout pass.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            TwelveTheme.applyAppTypographyToWheelDatePicker(self)
        }
    }
}

/// Wheel `UIDatePicker` with labels styled to match `TwelveTheme.appFont` (UIKit subtree).
struct TwelveAppWheelDatePicker: UIViewRepresentable {
    @Binding var selection: Date
    var mode: UIDatePicker.Mode
    var minuteInterval: Int = 1

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIView(context: Context) -> TwelveStyledWheelDatePicker {
        let picker = TwelveStyledWheelDatePicker()
        picker.datePickerMode = mode
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = minuteInterval
        picker.backgroundColor = TwelveTheme.backgroundSolidUIColor
        picker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        picker.date = selection
        TwelveTheme.applyAppTypographyToWheelDatePicker(picker)
        return picker
    }

    func updateUIView(_ uiView: TwelveStyledWheelDatePicker, context: Context) {
        uiView.datePickerMode = mode
        uiView.minuteInterval = minuteInterval
        uiView.backgroundColor = TwelveTheme.backgroundSolidUIColor
        if abs(uiView.date.timeIntervalSince(selection)) > 0.5 {
            uiView.date = selection
        }
        TwelveTheme.applyAppTypographyToWheelDatePicker(uiView)
    }

    final class Coordinator: NSObject {
        var selection: Binding<Date>

        init(selection: Binding<Date>) {
            self.selection = selection
        }

        @objc func valueChanged(_ sender: UIDatePicker) {
            selection.wrappedValue = sender.date
            TwelveTheme.applyAppTypographyToWheelDatePicker(sender)
        }
    }
}

extension TwelveTheme {
    /// Preferred UIKit font for picker wheels (mirrors `appFont` family, rounded system fallback).
    static func uiFontForApp(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if UIFont(name: "ChalkboardSE-Regular", size: size) != nil {
            switch weight {
            case .bold, .heavy, .black, .semibold, .medium:
                return UIFont(name: "ChalkboardSE-Bold", size: size)
                    ?? .systemFont(ofSize: size, weight: weight)
            default:
                return UIFont(name: "ChalkboardSE-Regular", size: size)
                    ?? .systemFont(ofSize: size, weight: weight)
            }
        }
        if UIFont(name: "Noteworthy-Light", size: size) != nil {
            switch weight {
            case .bold, .heavy, .black, .semibold, .medium:
                return UIFont(name: "Noteworthy-Bold", size: size)
                    ?? .systemFont(ofSize: size, weight: weight)
            default:
                return UIFont(name: "Noteworthy-Light", size: size)
                    ?? .systemFont(ofSize: size, weight: weight)
            }
        }
        if let wide = UIFont(name: "MarkerFelt-Wide", size: size) {
            return wide
        }
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let rounded = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: rounded, size: size)
        }
        return base
    }

    static func applyAppTypographyToWheelDatePicker(_ picker: UIView) {
        let font = uiFontForApp(size: 20, weight: .medium)
        let textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
                : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        }
        func styleLabels(in view: UIView) {
            if let label = view as? UILabel {
                label.font = font
                label.textColor = textColor
            }
            view.subviews.forEach { styleLabels(in: $0) }
        }
        styleLabels(in: picker)
        picker.backgroundColor = TwelveTheme.backgroundSolidUIColor
        // Wheel scroll views often use the grouped table background; tint to match the app sheet.
        func tintScrollViews(in view: UIView) {
            if let scroll = view as? UIScrollView {
                scroll.backgroundColor = TwelveTheme.backgroundSolidUIColor
            }
            view.subviews.forEach { tintScrollViews(in: $0) }
        }
        tintScrollViews(in: picker)
    }
}
