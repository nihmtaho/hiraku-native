import DesignSystem
import SwiftUI

@main
struct HirakuApp: App {
    init() {
        HKFont.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            root
        }
    }

    @ViewBuilder
    private var root: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["HK_SPIKE_S4"] == "1" {
            AdaptiveCheckView()
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
}
