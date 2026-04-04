import SwiftUI
import WidgetKit

@main
struct LedgerWidgetsAppBundle: WidgetBundle {
    var body: some Widget {
        TwelveDiaryWidget()
        LedgerNetWidget()
    }
}
