import SwiftUI

@main
struct HirakuApp: App {
    init() { NotoFont.register() }

    var body: some Scene {
        WindowGroup {
            ShellView()
        }
    }
}
