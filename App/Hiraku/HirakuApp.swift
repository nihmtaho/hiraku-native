import DesignSystem
import SwiftUI

@main
struct HirakuApp: App {
    init() {
        HKFont.registerBundledFonts()
        NotoFont.register()
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
        } else if ProcessInfo.processInfo.environment["HK_M0_SHELL"] == "1" {
            ShellView()
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
}
