import DesignSystem
import HirakuModels
import SwiftUI

/// Passive word list: rows, debounced search, empty states, delete confirmation and the add button.
public struct WordListView: View {
    private let controller: WordListController
    private let onBack: () -> Void
    private let onAdd: () -> Void
    private let onEdit: (Note) -> Void

    @State private var pendingDeletion: Note?

    public init(
        controller: WordListController,
        onBack: @escaping () -> Void,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (Note) -> Void
    ) {
        self.controller = controller
        self.onBack = onBack
        self.onAdd = onAdd
        self.onEdit = onEdit
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(controller.deck.name)
                .searchable(text: Binding(
                    get: { controller.searchText },
                    set: { controller.searchText = $0 }
                ), prompt: Text("words.search.prompt"))
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: onBack) {
                            AppIcon.chevronBack.image
                        }
                        .accessibilityLabel(Text("common.back"))
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: onAdd) {
                            AppIcon.add.image
                        }
                        .accessibilityLabel(Text("words.add"))
                    }
                }
                .confirmationDialog(
                    Text("words.delete.title \(pendingDeletion.map { term(of: $0) } ?? "")"),
                    isPresented: Binding(
                        get: { pendingDeletion != nil },
                        set: { if !$0 { pendingDeletion = nil } }
                    ),
                    presenting: pendingDeletion
                ) { note in
                    Button(role: .destructive) {
                        Task { await controller.delete(note) }
                        pendingDeletion = nil
                    } label: {
                        Text("delete")
                    }
                } message: { _ in
                    Text("words.delete.message")
                }
                .alert(
                    Text("error.generic.title"),
                    isPresented: Binding(
                        get: { controller.lastError != nil },
                        set: { if !$0 { controller.clearError() } }
                    )
                ) {
                    Button("common.close", role: .cancel) { controller.clearError() }
                } message: {
                    Text("error.generic.message")
                }
        }
        .task { controller.start() }
        .onDisappear { controller.stop() }
    }

    @ViewBuilder
    private var content: some View {
        switch controller.phase {
        case .loading:
            ProgressView()
        case .failed:
            ContentUnavailableView {
                Text("error.generic.title")
            } description: {
                Text("error.generic.message")
            } actions: {
                HKButton("common.retry") {
                    Task { await controller.load() }
                }
            }
        case .ready where controller.rows.isEmpty && !controller.searchText.isEmpty:
            ContentUnavailableView {
                Label {
                    Text("words.search.empty.title")
                } icon: {
                    AppIcon.search.image
                }
            } actions: {
                HKButton("words.search.empty.clear") {
                    Task { await controller.clearFilter() }
                }
            }
        case .ready where controller.rows.isEmpty:
            ContentUnavailableView {
                Label {
                    Text("words.empty.title")
                } icon: {
                    AppIcon.decks.image
                }
            } description: {
                Text("words.empty.message")
            } actions: {
                HKButton("words.empty.cta", action: onAdd)
            }
        case .ready:
            list
        }
    }

    private var list: some View {
        List(controller.rows) { note in
            Button {
                onEdit(note)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: HKSpacing.sm) {
                    StateDot(stateKind(of: note))
                        .accessibilityLabel(Text(stateLabel(of: note)))
                    VStack(alignment: .leading, spacing: HKSpacing.xs) {
                        HStack(alignment: .firstTextBaseline, spacing: HKSpacing.xs) {
                            Text(verbatim: term(of: note))
                                .font(HKFont.jpTerm.font())
                                .foregroundStyle(HKColor.primary)
                            let reading = readingValue(of: note)
                            if !reading.isEmpty && reading != term(of: note) {
                                Text(verbatim: reading)
                                    .font(HKFont.bodySM.font())
                                    .foregroundStyle(HKColor.secondary)
                            }
                        }
                        let meaning = meaningValue(of: note)
                        if !meaning.isEmpty {
                            Text(verbatim: meaning)
                                .font(HKFont.bodySM.font())
                                .foregroundStyle(HKColor.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("edit") { onEdit(note) }
                Divider()
                Button("delete", role: .destructive) { pendingDeletion = note }
            }
        }
    }

    private func term(of note: Note) -> String {
        guard let field = controller.noteType?.fields.first(where: { $0.role == .term }) else { return "" }
        return note.value(of: field.id)
    }

    private func meaningValue(of note: Note) -> String {
        guard let field = controller.noteType?.fields.first(where: { $0.role == .meaning }) else { return "" }
        return note.value(of: field.id)
    }

    private func readingValue(of note: Note) -> String {
        guard let field = controller.noteType?.fields.first(where: { $0.role == .reading }) else { return "" }
        return note.value(of: field.id)
    }

    private func stateKind(of note: Note) -> StateDot.Kind {
        switch note.state {
        case .new: .new
        case .learning: .learning
        case .known: .known
        }
    }

    private func stateLabel(of note: Note) -> LocalizedStringKey {
        switch note.state {
        case .new: "words.state.new"
        case .learning: "words.state.learning"
        case .known: "words.state.known"
        }
    }
}
