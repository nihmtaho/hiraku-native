import SwiftUI

public enum HKButtonVariant: Sendable {
    case primary
    case secondary
    case dark
}

/// Capsule button with the default, pressed, hover, focus and disabled states of DESIGN §Components.
public struct HKButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    private let title: LocalizedStringKey
    private let variant: HKButtonVariant
    private let action: () -> Void

    public init(_ title: LocalizedStringKey, variant: HKButtonVariant = .primary, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(HKFont.button.font())
                .tracking(HKFont.button.tracking())
        }
        .buttonStyle(HKButtonBody(variant: variant, hovering: hovering))
        .onHover { hovering = $0 }
        .opacity(isEnabled ? 1 : 0.4)
    }
}

private struct HKButtonBody: ButtonStyle {
    let variant: HKButtonVariant
    let hovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .padding(.horizontal, 20)
            .frame(minHeight: minHeight)
            .background(background(pressed: configuration.isPressed), in: Capsule())
            .overlay {
                if variant == .secondary {
                    Capsule().strokeBorder(HKColor.border, lineWidth: HKBorder.width)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }

    private var minHeight: CGFloat {
        #if os(macOS)
        HKControl.buttonPointer
        #else
        HKControl.buttonTouch
        #endif
    }

    private var foreground: Color {
        switch variant {
        case .primary: HKColor.onTertiary
        case .secondary: HKColor.primary
        case .dark: HKColor.onPrimary
        }
    }

    private func background(pressed: Bool) -> Color {
        switch variant {
        case .primary: (pressed || hovering) ? HKColor.tertiaryHover : HKColor.tertiary
        case .secondary: hovering ? HKColor.divider : HKColor.surface
        case .dark: hovering ? HKColor.tertiaryHover : HKColor.primary
        }
    }
}

/// Ink-bordered paper card: `RoundedRectangle` in the md radius, lg padding, no shadow.
public struct HKCard<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .foregroundStyle(HKColor.primary)
            .padding(HKSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HKColor.surface, in: shape)
            .overlay { shape.strokeBorder(HKColor.border, lineWidth: borderWidth) }
    }

    private var borderWidth: CGFloat {
        contrast == .increased ? HKBorder.increased : HKBorder.width
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HKRadius.md, style: .continuous)
    }
}

/// Labelled text field with the inline error row of DESIGN §Components; the error uses ink, never Ember.
public struct HKField: View {
    @Environment(\.colorSchemeContrast) private var contrast

    private let label: LocalizedStringKey
    private let placeholder: LocalizedStringKey
    @Binding private var text: String
    private let error: LocalizedStringKey?

    public init(
        _ label: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        error: LocalizedStringKey? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.error = error
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: HKSpacing.sm) {
            Text(label)
                .font(HKFont.labelCaps.font())
                .tracking(HKFont.labelCaps.tracking())
                .textCase(.uppercase)
                .foregroundStyle(labelColor)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(HKFont.bodyMD.font())
                .padding(HKSpacing.md)
                .background(HKColor.surface, in: shape)
                .overlay { shape.strokeBorder(HKColor.border, lineWidth: borderWidth) }
                .accessibilityLabel(Text(label))
            if let error {
                Label {
                    Text(error).font(HKFont.bodySM.font())
                } icon: {
                    AppIcon.wrong.image
                }
                .foregroundStyle(HKColor.primary)
            }
        }
    }

    private var labelColor: Color {
        contrast == .increased ? HKColor.primary : HKColor.secondary
    }

    private var borderWidth: CGFloat {
        contrast == .increased ? HKBorder.increased : HKBorder.width
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HKRadius.md, style: .continuous)
    }
}
