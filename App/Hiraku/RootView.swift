import DesignSystem
import FeatureDecks
import FeatureFolders
import FeatureWords
import HirakuModels
import SwiftUI

/// Opens the core once, then shows the folder feature; the M0 debug views stay behind a flag.
struct RootView: View {
    @State private var container = AppContainer()
    @State private var controller: FoldersController?
    @State private var decks: DecksController?
    @State private var words: WordListController?
    @State private var form: WordFormController?
    @State private var failure: String?

    var body: some View {
        Group {
            if let words {
                FeatureWords.list(
                    controller: words,
                    onBack: { self.words = nil },
                    onAdd: { openForm(nil) },
                    onEdit: { note in openForm(note) }
                )
                .sheet(
                    isPresented: Binding(
                        get: { form != nil },
                        set: { if !$0 { form = nil } }
                    )
                ) {
                    if let form {
                        FeatureWords.form(
                            controller: form,
                            onFinished: {},
                            onViewExisting: { _ in }
                        )
                    }
                }
            } else if let decks {
                FeatureDecks.screen(
                    controller: decks,
                    onBack: { self.decks = nil; self.words = nil },
                    openDeck: { deck in
                        guard let catalog = container.catalog else { return }
                        words = FeatureWords.makeListController(
                            deck: deck,
                            notes: catalog,
                            noteTypes: catalog,
                            events: container.events,
                            clock: container.clock
                        )
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

    private func openForm(_ note: Note?) {
        guard let catalog = container.catalog, let deck = words?.deck, let noteType = words?.noteType else { return }
        form = FeatureWords.makeFormController(deck: deck, noteType: noteType, note: note, notes: catalog)
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
