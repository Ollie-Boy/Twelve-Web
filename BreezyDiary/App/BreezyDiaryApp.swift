import SwiftUI

@main
struct BreezyDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(BreezyTheme.handwrittenFont(size: 16))
        }
    }
}
