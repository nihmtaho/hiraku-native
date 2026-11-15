import HirakuModels
import SwiftUI

/// Entry point of the word feature; the app owns both controllers.
public enum FeatureWords {
    @MainActor public static func makeListController(
        deck: Deck,
        notes: any NoteRepository,
        noteTypes: any NoteTypeRepository,
        events: any ChangeEvents,
        clock: any AppClock
    ) -> WordListController {
        WordListController(deck: deck, notes: notes, noteTypes: noteTypes, events: events, clock: clock)
    }

    @MainActor public static func makeFormController(
        deck: Deck,
        noteType: NoteType,
        note: Note?,
        notes: any NoteRepository
    ) -> WordFormController {
        WordFormController(deck: deck, noteType: noteType, note: note, notes: notes)
    }

    @MainActor public static func list(
        controller: WordListController,
        onBack: @escaping () -> Void,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (Note) -> Void
    ) -> some View {
        WordListView(controller: controller, onBack: onBack, onAdd: onAdd, onEdit: onEdit)
    }

    @MainActor public static func form(
        controller: WordFormController,
        onFinished: @escaping () -> Void,
        onViewExisting: @escaping (String) -> Void
    ) -> some View {
        WordFormView(controller: controller, onFinished: onFinished, onViewExisting: onViewExisting)
    }
}
