import QuartzCore
import SwiftUI
import UIKit

/// Subclasses `UIDatePicker` so fonts stay correct while the wheel scrolls (system resets row views during tracking).
final class TwelveStyledWheelDatePicker: UIDatePicker {
    private var fontRefreshLink: CADisplayLink?

    deinit {
        stopFontRefreshLink()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        TwelveTheme.applyAppTypographyToWheelDatePicker(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startFontRefreshLink()
            TwelveTheme.applyAppTypographyToWheelDatePicker(self)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                TwelveTheme.applyAppTypographyToWheelDatePicker(self)
            }
        } else {
            stopFontRefreshLink()
        }
    }

    private func startFontRefreshLink() {
        stopFontRefreshLink()
        let link = CADisplayLink(target: self, selector: #selector(fontRefreshTick))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        fontRefreshLink = link
    }

    private func stopFontRefreshLink() {
        fontRefreshLink?.invalidate()
        fontRefreshLink = nil
    }

    @objc private func fontRefreshTick() {
        TwelveTheme.applyAppTypographyToWheelDatePicker(self)
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
    static func applyAppTypographyToWheelDatePicker(_ picker: UIView) {
        let font = uiFontForApp(size: 20, weight: UIFont.Weight.medium)
        let textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
                : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        }

        func applyToLabel(_ label: UILabel) {
            if label.attributedText != nil {
                let plain = label.attributedText?.string ?? label.text ?? ""
                label.attributedText = nil
                label.text = plain
            }
            label.font = font
            label.textColor = textColor
        }

        func styleViews(in view: UIView) {
            if let label = view as? UILabel {
                applyToLabel(label)
            } else if let field = view as? UITextField {
                field.font = font
                field.textColor = textColor
                var attrs = field.defaultTextAttributes
                attrs[.font] = font
                attrs[.foregroundColor] = textColor
                field.defaultTextAttributes = attrs
            }
            view.subviews.forEach { styleViews(in: $0) }
        }

        styleViews(in: picker)
        picker.backgroundColor = TwelveTheme.backgroundSolidUIColor

        func tintScrollViews(in view: UIView) {
            if let scroll = view as? UIScrollView {
                scroll.backgroundColor = TwelveTheme.backgroundSolidUIColor
            }
            view.subviews.forEach { tintScrollViews(in: $0) }
        }
        tintScrollViews(in: picker)
    }
}
