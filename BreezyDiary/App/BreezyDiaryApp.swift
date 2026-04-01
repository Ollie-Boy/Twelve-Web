import SwiftUI

@main
struct BreezyDiaryApp: App {
    @StateObject private var appearance = AppearanceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(BreezyTheme.handwrittenFont(size: 16))
                .environmentObject(appearance)
                .preferredColorScheme(appearance.preferredColorScheme)
        }
    }
}
