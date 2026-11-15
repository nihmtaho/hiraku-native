import Foundation
import HirakuModels
import HirakuTesting
import Testing

@testable import FeatureWords

private let deck = Deck(
    id: DeckID(rawValue: "d1"),
    folderID: FolderID(rawValue: "f1"),
    name: "Động từ",
    description: "",
    position: 1,
    noteTypeID: NoteTypeID(rawValue: "nt-system-ja"),
    noteCount: 0,
    stateCounts: StateCounts(new: 0, learning: 0, known: 0)
)

private let noteType = NoteType(
    id: NoteTypeID(rawValue: "nt-system-ja"),
    name: "Từ vựng Nhật",
    isSystem: true,
    fields: [
        NoteTypeField(id: "nf-term", role: .term, name: "Từ", ord: 1, inputKind: .text, required: true, searchable: true),
        NoteTypeField(id: "nf-reading", role: .reading, name: "Cách đọc", ord: 2, inputKind: .kana, required: false, searchable: true),
        NoteTypeField(id: "nf-meaning", role: .meaning, name: "Nghĩa", ord: 3, inputKind: .text, required: true, searchable: true),
    ],
    frontFieldIDs: ["nf-term"],
    backFieldIDs: ["nf-reading", "nf-meaning"],
    typingAnswerFieldID: "nf-reading"
)

@MainActor
private func makeForm(note: Note? = nil, catalog: FakeCatalog) -> WordFormController {
    WordFormController(deck: deck, noteType: noteType, note: note, notes: catalog)
}

@MainActor
@Test func requiredFieldsBlockSavingWithRoleSpecificErrors() async {
    let form = makeForm(catalog: FakeCatalog(noteTypes: [noteType]))
    #expect(!form.validate())
    #expect(form.errors["nf-term"] == "words.error.word.empty")
    #expect(form.errors["nf-meaning"] == "words.error.meaning.empty")
    #expect(await form.save() == .invalid)
}

@MainActor
@Test func emptyReadingIsAllowed() async throws {
    let catalog = FakeCatalog(noteTypes: [noteType])
    let form = makeForm(catalog: catalog)
    form.setValue("食べる", for: "nf-term")
    form.setValue("ăn", for: "nf-meaning")
    #expect(await form.save() == .saved)
    let savedPage = try await catalog.notes(in: deck.id, query: NoteQuery())
    #expect(savedPage.total == 1)
}

@MainActor
@Test func duplicateTermWarnsAndStillSavesWhenForced() async throws {
    let catalog = FakeCatalog(noteTypes: [noteType])
    let seeded = makeForm(catalog: catalog)
    seeded.setValue("食べる", for: "nf-term")
    seeded.setValue("ăn", for: "nf-meaning")
    _ = await seeded.save()

    let form = makeForm(catalog: catalog)
    form.setValue("食べる", for: "nf-term")
    form.setValue("dùng bữa", for: "nf-meaning")
    let outcome = await form.save()
    #expect(outcome == .duplicate(DuplicateTerm(exists: true, meaning: "ăn")))
    let afterWarning = try await catalog.notes(in: deck.id, query: NoteQuery())
    #expect(afterWarning.total == 1)

    #expect(await form.saveIgnoringDuplicate())
    let afterForced = try await catalog.notes(in: deck.id, query: NoteQuery())
    #expect(afterForced.total == 2)
}

@MainActor
@Test func editingTheSameTermDoesNotWarnAboutItself() async throws {
    let catalog = FakeCatalog(noteTypes: [noteType])
    let seeded = makeForm(catalog: catalog)
    seeded.setValue("食べる", for: "nf-term")
    seeded.setValue("ăn", for: "nf-meaning")
    _ = await seeded.save()
    let saved = try #require(try await catalog.notes(in: deck.id, query: NoteQuery()).notes.first)

    let form = makeForm(note: saved, catalog: catalog)
    form.setValue("食べる", for: "nf-term")
    form.setValue("dùng bữa", for: "nf-meaning")
    #expect(await form.save() == .saved)
}

@MainActor
@Test func hasChangesTracksTheDraft() {
    let form = makeForm(catalog: FakeCatalog(noteTypes: [noteType]))
    #expect(!form.hasChanges)
    form.setValue("水", for: "nf-term")
    #expect(form.hasChanges)
    form.setValue("", for: "nf-term")
    #expect(!form.hasChanges)
}

@MainActor
@Test func listLoadsSearchesAndDeletes() async throws {
    let catalog = FakeCatalog(noteTypes: [noteType])
    let form = makeForm(catalog: catalog)
    form.setValue("水", for: "nf-term")
    form.setValue("nước", for: "nf-meaning")
    _ = await form.save()

    let list = WordListController(
        deck: deck,
        notes: catalog,
        noteTypes: catalog,
        events: FakeChangeEvents(),
        clock: ManualClock()
    )
    await list.loadNoteType()
    await list.load()
    #expect(list.noteType?.typingAnswerFieldID == "nf-reading")
    #expect(list.rows.count == 1)
    #expect(list.total == 1)

    list.searchText = "nướ"
    await list.load()
    #expect(list.rows.count == 1)

    await list.delete(list.rows[0])
    #expect(list.rows.isEmpty)
}
