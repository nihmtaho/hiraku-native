import DesignSystem
import FeatureDecks
import FeatureFolders
import HirakuModels
import SwiftUI

/// Opens the core once, then shows the folder feature; the M0 debug views stay behind a flag.
struct RootView: View {
    @State private var container = AppContainer()
    @State private var controller: FoldersController?
    @State private var decks: DecksController?
    @State private var failure: String?

    var body: some View {
        Group {
            if let decks {
                FeatureDecks.screen(
                    controller: decks,
                    onBack: { self.decks = nil },
                    openDeck: { _ in
                        // The word list arrives with FeatureWords.
                    }
                )
            } else if let controller {
                FeatureFolders.screen(controller: controller) { folder in
                    guard let catalog = container.catalog else { return }
                    decks = FeatureDecks.makeController(
                        folder: folder,
                        decks: catalog,
                        folders: catalog,
                        noteTypes: catalog,
                        events: container.events,
                        clock: container.clock
                    )
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
