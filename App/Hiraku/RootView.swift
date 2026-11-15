import DesignSystem
import FeatureFolders
import HirakuModels
import SwiftUI

/// Opens the core once, then shows the folder feature; the M0 debug views stay behind a flag.
struct RootView: View {
    @State private var container = AppContainer()
    @State private var controller: FoldersController?
    @State private var failure: String?

    var body: some View {
        Group {
            if let controller {
                FeatureFolders.screen(controller: controller) { _ in
                    // The deck screen arrives with FeatureDecks.
                }
            } else if failure != nil {
                ContentUnavailableView {
                    Text("error.generic.title")
                } description: {
                    Text("error.generic.message")
                }
            } else {
                ProgressView()
            }
        }
        .tint(HKColor.tertiary)
        .frame(minWidth: 720, minHeight: 520)
        .task { await open() }
    }

    private func open() async {
        guard controller == nil else { return }
        do {
            try await container.start()
            guard let catalog = container.catalog else { return }
            controller = FeatureFolders.makeController(
                folders: catalog,
                events: container.events,
                clock: container.clock
            )
        } catch {
            failure = "error.generic.message"
        }
    }
}
