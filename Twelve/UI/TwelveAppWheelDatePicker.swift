import SwiftUI
import UIKit

/// Wheel `UIDatePicker` with labels styled to match `TwelveTheme.appFont` (UIKit subtree).
struct TwelveAppWheelDatePicker: UIViewRepresentable {
    @Binding var selection: Date
    var mode: UIDatePicker.Mode
    var minuteInterval: Int = 1

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = mode
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = minuteInterval
        picker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        picker.date = selection
        TwelveTheme.applyAppTypographyToWheelDatePicker(picker)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.datePickerMode = mode
        uiView.minuteInterval = minuteInterval
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

    static func applyAppTypographyToWheelDatePicker(_ picker: UIDatePicker) {
        let font = uiFontForApp(size: 20, weight: .medium)
        func styleLabels(in view: UIView) {
            if let label = view as? UILabel {
                label.font = font
            }
            view.subviews.forEach { styleLabels(in: $0) }
        }
        styleLabels(in: picker)
    }
}
