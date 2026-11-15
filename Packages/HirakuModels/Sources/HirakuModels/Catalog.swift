import Foundation

/// A top-level grouping of decks with the counts its meta line shows.
public struct Folder: Identifiable, Equatable, Sendable {
    public let id: FolderID
    public var name: String
    public var position: Int
    public var deckCount: Int
    public var noteCount: Int

    public init(id: FolderID, name: String, position: Int, deckCount: Int, noteCount: Int) {
        self.id = id
        self.name = name
        self.position = position
        self.deckCount = deckCount
        self.noteCount = noteCount
    }
}

/// How many notes of a deck sit in each study state.
public struct StateCounts: Equatable, Sendable {
    public var new: Int
    public var learning: Int
    public var known: Int

    public init(new: Int, learning: Int, known: Int) {
        self.new = new
        self.learning = learning
        self.known = known
    }
}

/// A deck belongs to one folder and keeps one note type for its lifetime.
public struct Deck: Identifiable, Equatable, Sendable {
    public let id: DeckID
    public var folderID: FolderID
    public var name: String
    public var description: String
    public var position: Int
    public var noteTypeID: NoteTypeID
    public var noteCount: Int
    public var stateCounts: StateCounts

    public init(
        id: DeckID,
        folderID: FolderID,
        name: String,
        description: String,
        position: Int,
        noteTypeID: NoteTypeID,
        noteCount: Int,
        stateCounts: StateCounts
    ) {
        self.id = id
        self.folderID = folderID
        self.name = name
        self.description = description
        self.position = position
        self.noteTypeID = noteTypeID
        self.noteCount = noteCount
        self.stateCounts = stateCounts
    }
}

public enum FieldRole: String, Sendable {
    case term
    case reading
    case meaning
    case example
    case text
}

public enum InputKind: String, Sendable {
    case text
    case kana
}

/// One field definition of a note type; the role, never the name, drives behaviour.
public struct NoteTypeField: Identifiable, Equatable, Sendable {
    public let id: String
    public var role: FieldRole
    public var name: String
    public var ord: Int
    public var inputKind: InputKind
    public var required: Bool
    public var searchable: Bool

    public init(
        id: String,
        role: FieldRole,
        name: String,
        ord: Int,
        inputKind: InputKind,
        required: Bool,
        searchable: Bool
    ) {
        self.id = id
        self.role = role
        self.name = name
        self.ord = ord
        self.inputKind = inputKind
        self.required = required
        self.searchable = searchable
    }
}

/// A note type with its ordered fields and its single card template.
public struct NoteType: Identifiable, Equatable, Sendable {
    public let id: NoteTypeID
    public var name: String
    public var isSystem: Bool
    public var fields: [NoteTypeField]
    public var frontFieldIDs: [String]
    public var backFieldIDs: [String]
    public var typingAnswerFieldID: String?

    public init(
        id: NoteTypeID,
        name: String,
        isSystem: Bool,
        fields: [NoteTypeField],
        frontFieldIDs: [String],
        backFieldIDs: [String],
        typingAnswerFieldID: String?
    ) {
        self.id = id
        self.name = name
        self.isSystem = isSystem
        self.fields = fields
        self.frontFieldIDs = frontFieldIDs
        self.backFieldIDs = backFieldIDs
        self.typingAnswerFieldID = typingAnswerFieldID
    }

    public func field(_ id: String) -> NoteTypeField? {
        fields.first { $0.id == id }
    }
}

public enum NoteState: Equatable, Sendable {
    case new
    case learning
    case known
}

/// One field value of a note, kept ordered by the note type.
public struct NoteFieldValue: Identifiable, Equatable, Sendable {
    public var fieldID: String
    public var value: String

    public var id: String { fieldID }

    public init(fieldID: String, value: String) {
        self.fieldID = fieldID
        self.value = value
    }
}

/// A note as the core stores it: a deck, ordered field values and a study state.
public struct Note: Identifiable, Equatable, Sendable {
    public let id: NoteID
    public var deckID: DeckID
    public var fields: [NoteFieldValue]
    public var state: NoteState

    public init(id: NoteID, deckID: DeckID, fields: [NoteFieldValue], state: NoteState) {
        self.id = id
        self.deckID = deckID
        self.fields = fields
        self.state = state
    }

    public func value(of fieldID: String) -> String {
        fields.first { $0.fieldID == fieldID }?.value ?? ""
    }
}

public struct NotePage: Equatable, Sendable {
    public var notes: [Note]
    public var total: Int

    public init(notes: [Note], total: Int) {
        self.notes = notes
        self.total = total
    }
}

public struct NoteQuery: Equatable, Sendable {
    public var text: String
    public var limit: Int
    public var offset: Int

    public init(text: String = "", limit: Int = 100, offset: Int = 0) {
        self.text = text
        self.limit = limit
        self.offset = offset
    }
}

/// Result of the duplicate check: a warning, never a block.
public struct DuplicateTerm: Equatable, Sendable {
    public var exists: Bool
    public var meaning: String

    public init(exists: Bool, meaning: String) {
        self.exists = exists
        self.meaning = meaning
    }
}
