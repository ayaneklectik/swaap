import SwiftUI

@main
struct SwaapMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 420)
    }
}
