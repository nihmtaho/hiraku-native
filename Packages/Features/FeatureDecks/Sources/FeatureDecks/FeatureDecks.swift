import HirakuModels
import SwiftUI

/// Entry point of the deck feature; the app owns the controller so its state survives redraws.
public enum FeatureDecks {
    @MainActor public static func makeController(
        folder: Folder,
        decks: any DeckRepository,
        folders: any FolderRepository,
        noteTypes: any NoteTypeRepository,
        events: any ChangeEvents
    ) -> DecksController {
        DecksController(
            folder: folder,
            decks: decks,
            folders: folders,
            noteTypes: noteTypes,
            events: events
        )
    }

    @MainActor public static func screen(
        controller: DecksController,
        onBack: @escaping () -> Void,
        openDeck: @escaping (Deck) -> Void
    ) -> some View {
        DecksView(controller: controller, onBack: onBack, openDeck: openDeck)
    }
}
