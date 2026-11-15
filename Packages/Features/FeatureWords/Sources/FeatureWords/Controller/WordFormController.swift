import Foundation
import HirakuModels

/// One word form: values keyed by field, per-field errors, the duplicate warning and the save path.
@MainActor @Observable
public final class WordFormController {
    public enum Outcome: Equatable, Sendable {
        case saved
        case invalid
        case duplicate(DuplicateTerm)
    }

    public private(set) var errors: [String: String] = [:]
    public private(set) var duplicate: DuplicateTerm?
    public private(set) var isSaving = false
    public private(set) var lastError: String?

    public let noteType: NoteType
    public private(set) var initialValues: [String: String]
    public private(set) var values: [String: String]

    private let deck: Deck
    private let notes: any NoteRepository
    private let editing: Note?

    public init(deck: Deck, noteType: NoteType, note: Note?, notes: any NoteRepository) {
        self.deck = deck
        self.noteType = noteType
        self.editing = note
        self.notes = notes
        let seed = Dictionary(uniqueKeysWithValues: (note?.fields ?? []).map { ($0.fieldID, $0.value) })
        self.initialValues = seed
        self.values = seed
    }

    public var isEditing: Bool { editing != nil }

    public var hasChanges: Bool { values != initialValues }

    public var orderedFields: [NoteTypeField] {
        noteType.fields.sorted { $0.ord < $1.ord }
    }

    public func value(of fieldID: String) -> String {
        values[fieldID] ?? ""
    }

    public func setValue(_ value: String, for fieldID: String) {
        values[fieldID] = value.isEmpty ? nil : value
        errors[fieldID] = nil
        duplicate = nil
    }

    public func validate() -> Bool {
        var found: [String: String] = [:]
        for field in orderedFields {
            let trimmed = value(of: field.id).trimmingCharacters(in: .whitespacesAndNewlines)
            if field.required && trimmed.isEmpty {
                found[field.id] = field.role == .term ? "words.error.word.empty"
                    : field.role == .meaning ? "words.error.meaning.empty"
                    : "required"
            }
        }
        errors = found
        return found.isEmpty
    }

    /// A duplicate term warns; it never blocks, so the caller decides to keep or override.
    public func save() async -> Outcome {
        guard validate() else { return .invalid }
        do {
            if let term = termValue(), let found = try await duplicateWarning(term: term) {
                duplicate = found
                return .duplicate(found)
            }
            return await persist()
        } catch {
            lastError = "error.save.failed"
            return .invalid
        }
    }

    public func saveIgnoringDuplicate() async -> Bool {
        guard validate() else { return false }
        if case .saved = await persist() { return true }
        return false
    }

    private func persist() async -> Outcome {
        isSaving = true
        defer { isSaving = false }
        do {
            let fieldValues = orderedFields
                .map { NoteFieldValue(fieldID: $0.id, value: value(of: $0.id).trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.value.isEmpty }
            if let editing {
                try await notes.updateNote(editing.id, values: fieldValues)
            } else {
                _ = try await notes.createNote(in: deck.id, values: fieldValues)
            }
            return .saved
        } catch {
            lastError = "error.save.failed"
            return .invalid
        }
    }

    private func termValue() -> String? {
        guard let termField = orderedFields.first(where: { $0.role == .term }) else { return nil }
        return value(of: termField.id).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Editing a word must not warn about itself.
    private func duplicateWarning(term: String) async throws -> DuplicateTerm? {
        guard !term.isEmpty else { return nil }
        let found = try await notes.duplicate(in: deck.id, term: term)
        if isEditing, found.exists, let editing, editing.value(of: termFieldID()) == term {
            return nil
        }
        return found.exists ? found : nil
    }

    private func termFieldID() -> String {
        orderedFields.first { $0.role == .term }?.id ?? ""
    }

    /// Clears the form for the next word after "save and add another".
    public func resetForNext() {
        values = [:]
        initialValues = [:]
        errors = [:]
        duplicate = nil
    }

    public func clearError() {
        lastError = nil
    }
}
