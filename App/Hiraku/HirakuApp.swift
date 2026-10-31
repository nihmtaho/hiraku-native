import SwiftUI

@main
struct HirakuApp: App {
    init() { NotoFont.register() }

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
            ShellView()
        }
        #else
        ShellView()
        #endif
    }
}
