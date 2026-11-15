import Foundation

/// Navigation values a feature may ask the app to open; routes never carry a feature.
public enum Route: Hashable, Sendable {
    case folders
    case deck(DeckID)
    case wordForm(deck: DeckID, note: NoteID?)
    case settings
}
