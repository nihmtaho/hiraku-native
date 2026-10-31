import SwiftUI

// Single real text field so IME, suggestions and VoiceOver stay native.
// SwiftUI does not expose marked text, so the platform field is wrapped.
struct KanaInputField {
    @Binding var text: String
    @Binding var isComposing: Bool
    var probe: ImeProbe?
    var onSubmit: () -> Void
}

// Lets debug code drive the native field's marked text without a real IME.
@MainActor
final class ImeProbe {
    fileprivate var setMarked: ((String) -> Void)?
    fileprivate var unmark: (() -> Void)?
    fileprivate var pressReturn: (() -> Void)?

    func compose(_ marked: String) { setMarked?(marked) }
    func commit() { unmark?() }
    func returnKey() { pressReturn?() }
}

#if canImport(UIKit)
import UIKit

extension KanaInputField: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 20)
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed), for: .editingChanged)
        context.coordinator.attach(field)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        // Never overwrite while composing: it would cancel the marked text.
        if field.markedTextRange == nil, field.text != text { field.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KanaInputField
        init(_ parent: KanaInputField) { self.parent = parent }

        func attach(_ field: UITextField) {
            parent.probe?.setMarked = { [weak self, weak field] in
                field?.setMarkedText($0, selectedRange: NSRange(location: $0.utf16.count, length: 0))
                self?.changed(field)
            }
            parent.probe?.unmark = { [weak self, weak field] in
                field?.unmarkText()
                self?.changed(field)
            }
            parent.probe?.pressReturn = { [weak self, weak field] in
                if let field { _ = self?.textFieldShouldReturn(field) }
            }
        }

        @objc func changed(_ sender: UITextField?) {
            guard let sender else { return }
            parent.text = sender.text ?? ""
            parent.isComposing = sender.markedTextRange != nil
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            // Return that confirms a conversion must not count as a submit.
            if field.markedTextRange != nil {
                field.unmarkText()
                changed(field)
            } else {
                parent.onSubmit()
            }
            return false
        }
    }
}

#elseif canImport(AppKit)
import AppKit

extension KanaInputField: NSViewRepresentable {
    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.font = .systemFont(ofSize: 20)
        context.coordinator.attach(field)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        let composing = (field.currentEditor() as? NSTextView)?.hasMarkedText() ?? false
        if !composing, field.stringValue != text { field.stringValue = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: KanaInputField
        init(_ parent: KanaInputField) { self.parent = parent }

        private func editor(of field: NSTextField?) -> NSTextView? {
            field?.currentEditor() as? NSTextView
        }

        func attach(_ field: NSTextField) {
            parent.probe?.setMarked = { [weak self, weak field] in
                guard let editor = self?.editor(of: field) else { return }
                editor.setMarkedText($0, selectedRange: NSRange(location: $0.utf16.count, length: 0),
                                     replacementRange: NSRange(location: NSNotFound, length: 0))
                self?.sync(field)
            }
            parent.probe?.unmark = { [weak self, weak field] in
                self?.editor(of: field)?.unmarkText()
                self?.sync(field)
            }
            parent.probe?.pressReturn = { [weak self, weak field] in
                guard let self, let field, let editor = self.editor(of: field) else { return }
                _ = self.control(field, textView: editor,
                                 doCommandBy: #selector(NSResponder.insertNewline(_:)))
            }
        }

        func controlTextDidChange(_ note: Notification) { sync(note.object as? NSTextField) }

        private func sync(_ field: NSTextField?) {
            guard let field else { return }
            parent.text = field.stringValue
            parent.isComposing = editor(of: field)?.hasMarkedText() ?? false
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard selector == #selector(NSResponder.insertNewline(_:)) else { return false }
            // Return that confirms a conversion must not count as a submit.
            if textView.hasMarkedText() { return false }
            parent.onSubmit()
            return true
        }
    }
}
#endif
