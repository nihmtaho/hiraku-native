import DesignSystem
import HirakuModels
import SwiftUI

/// Form built from the note type's fields: required rules, duplicate warning and unsaved-change guard.
public struct WordFormView: View {
    private let controller: WordFormController
    private let onFinished: () -> Void
    private let onViewExisting: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDiscard = false
    @State private var keepOpen = false
    @FocusState private var focusedField: String?

    public init(
        controller: WordFormController,
        onFinished: @escaping () -> Void,
        onViewExisting: @escaping (String) -> Void
    ) {
        self.controller = controller
        self.onFinished = onFinished
        self.onViewExisting = onViewExisting
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HKSpacing.lg) {
                    ForEach(controller.orderedFields) { field in
                        fieldRow(field)
                    }
                    if let duplicate = controller.duplicate {
                        duplicateBox(duplicate)
                    }
                }
                .padding(HKSpacing.lg)
            }
            .navigationTitle(controller.isEditing ? Text("words.edit.title") : Text("words.create.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        if controller.hasChanges { showDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    HStack(spacing: HKSpacing.sm) {
                        if !controller.isEditing {
                            Button("words.saveAndNext") {
                                Task { await save(andNext: true) }
                            }
                            .disabled(controller.isSaving)
                        }
                        Button("common.save") {
                            Task { await save(andNext: false) }
                        }
                        .disabled(controller.isSaving)
                    }
                }
            }
            .confirmationDialog(
                Text("discard.title"),
                isPresented: $showDiscard
            ) {
                Button("discard.confirm", role: .destructive) { dismiss() }
                Button("discard.cancel", role: .cancel) {}
            } message: {
                Text("discard.message")
            }
            .interactiveDismissDisabled(controller.hasChanges)
            .alert(
                Text("error.generic.title"),
                isPresented: Binding(
                    get: { controller.lastError != nil },
                    set: { if !$0 { controller.clearError() } }
                )
            ) {
                Button("common.close", role: .cancel) { controller.clearError() }
            } message: {
                Text("error.save.failed")
            }
        }
        .onAppear { focusedField = controller.orderedFields.first?.id }
    }

    private func fieldRow(_ field: NoteTypeField) -> some View {
        VStack(alignment: .leading, spacing: HKSpacing.xs) {
            HStack(spacing: HKSpacing.xs) {
                Text(verbatim: field.name)
                    .font(HKFont.labelCaps.font())
                    .tracking(HKFont.labelCaps.tracking())
                    .textCase(.uppercase)
                    .foregroundStyle(HKColor.secondary)
                if field.required {
                    Text("required")
                        .font(HKFont.bodySM.font())
                        .foregroundStyle(HKColor.secondary)
                }
            }
            TextField(placeholder(field), text: binding(field))
                .textFieldStyle(.plain)
                .font(field.role == .term ? HKFont.jpTerm.font() : HKFont.bodyMD.font())
                .padding(HKSpacing.md)
                .background(HKColor.surface, in: shape)
                .overlay { shape.strokeBorder(HKColor.border, lineWidth: HKBorder.width) }
                .focused($focusedField, equals: field.id)
                .accessibilityLabel(Text(verbatim: field.name))
            if field.role == .reading {
                Text("words.field.reading.hint")
                    .font(HKFont.bodySM.font())
                    .foregroundStyle(HKColor.secondary)
            }
            if let message = controller.errors[field.id] {
                Label {
                    Text(LocalizedStringKey(message)).font(HKFont.bodySM.font())
                } icon: {
                    AppIcon.wrong.image
                }
                .foregroundStyle(HKColor.primary)
            }
        }
    }

    private func duplicateBox(_ duplicate: DuplicateTerm) -> some View {
        VStack(alignment: .leading, spacing: HKSpacing.sm) {
            Text("words.duplicate.title \(duplicate.meaning)")
                .font(HKFont.bodyMD.font())
                .foregroundStyle(HKColor.primary)
            HStack(spacing: HKSpacing.sm) {
                HKButton("words.duplicate.addAnyway") {
                    Task {
                        if await controller.saveIgnoringDuplicate() {
                            onFinished()
                            dismiss()
                        }
                    }
                }
                Button("words.duplicate.viewExisting") {
                    onViewExisting(duplicate.meaning)
                    dismiss()
                }
            }
        }
        .padding(HKSpacing.md)
        .background(HKColor.tertiaryContainer, in: shape)
        .overlay { shape.strokeBorder(HKColor.tertiary, lineWidth: HKBorder.width) }
    }

    private func save(andNext: Bool) async {
        switch await controller.save() {
        case .saved:
            onFinished()
            if andNext {
                controller.resetForNext()
                focusedField = controller.orderedFields.first?.id
            } else {
                dismiss()
            }
        case .duplicate, .invalid:
            break
        }
    }

    private func binding(_ field: NoteTypeField) -> Binding<String> {
        Binding(
            get: { controller.value(of: field.id) },
            set: { controller.setValue($0, for: field.id) }
        )
    }

    private func placeholder(_ field: NoteTypeField) -> LocalizedStringKey {
        switch field.role {
        case .term: "words.field.word.placeholder"
        case .reading: "words.field.reading.placeholder"
        case .meaning: "words.field.meaning.placeholder"
        case .example: "words.field.example.placeholder"
        case .text: LocalizedStringKey(field.name)
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HKRadius.md, style: .continuous)
    }
}
