import Combine
import SwiftUI

/// Bumps when font scale changes so SwiftUI re-evaluates `TwelveTheme.appFont` sizes.
final class TypographyRefreshNotifier: ObservableObject {
    static let shared = TypographyRefreshNotifier()
    @Published private(set) var generation: Int = 0
    private var cancellable: AnyCancellable?

    private init() {
        cancellable = NotificationCenter.default.publisher(for: .appFontScaleDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.generation += 1
            }
    }
}
