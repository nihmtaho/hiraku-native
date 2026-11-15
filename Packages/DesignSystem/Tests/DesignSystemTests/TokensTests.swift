import CoreText
import SwiftUI
import Testing

@testable import DesignSystem

@Test func coloursMatchDesignTokens() throws {
    let tokens: [(UInt32, UInt32)] = [
        (HKHex.primary, 0x16130F),
        (HKHex.secondary, 0x6B655C),
        (HKHex.tertiary, 0xFF4D2E),
        (HKHex.tertiaryHover, 0xE83F1F),
        (HKHex.tertiaryContainer, 0xFFE9E3),
        (HKHex.onTertiary, 0xFFFFFF),
        (HKHex.neutral, 0xF4F1EA),
        (HKHex.surface, 0xFFFDF8),
        (HKHex.onPrimary, 0xF4F1EA),
        (HKHex.border, 0x16130F),
        (HKHex.borderSoft, 0xDED8CC),
        (HKHex.divider, 0xE8E3D9),
        (HKHex.faint, 0xA39C8F),
        (HKHex.stateNew, 0x3A6EA5),
        (HKHex.stateLearning, 0xD9A300),
        (HKHex.stateLearningInk, 0xA67C00),
        (HKHex.stateKnown, 0x2F9E6F),
        (HKHex.kanaFill, 0xF0F8F4),
    ]
    for (token, documented) in tokens {
        #expect(token == documented)
    }
}

@Test func colourTokensAreBuiltFromTheHexTable() throws {
    #if canImport(AppKit)
    let tokens: [(Color, UInt32)] = [
        (HKColor.primary, HKHex.primary),
        (HKColor.secondary, HKHex.secondary),
        (HKColor.tertiary, HKHex.tertiary),
        (HKColor.tertiaryHover, HKHex.tertiaryHover),
        (HKColor.tertiaryContainer, HKHex.tertiaryContainer),
        (HKColor.onTertiary, HKHex.onTertiary),
        (HKColor.neutral, HKHex.neutral),
        (HKColor.surface, HKHex.surface),
        (HKColor.onPrimary, HKHex.onPrimary),
        (HKColor.border, HKHex.border),
        (HKColor.borderSoft, HKHex.borderSoft),
        (HKColor.divider, HKHex.divider),
        (HKColor.faint, HKHex.faint),
        (HKColor.stateNew, HKHex.stateNew),
        (HKColor.stateLearning, HKHex.stateLearning),
        (HKColor.stateLearningInk, HKHex.stateLearningInk),
        (HKColor.stateKnown, HKHex.stateKnown),
        (HKColor.kanaFill, HKHex.kanaFill),
    ]
    for (color, hex) in tokens {
        #expect(rgb(color) == hex, "expected \(hex), measured \(rgb(color))")
    }
    #endif
}

@Test func stateLearningSplitsInkFromFill() throws {
    #expect(HKHex.stateLearningInk == 0xA67C00)
    #expect(HKHex.stateLearning == 0xD9A300)
}

@Test func contrastPairsMeetTheDesignTable() throws {
    let pairs: [(UInt32, UInt32, Double)] = [
        (HKHex.primary, HKHex.neutral, 16.41),
        (HKHex.primary, HKHex.surface, 18.21),
        (HKHex.secondary, HKHex.neutral, 5.11),
        (HKHex.secondary, HKHex.surface, 5.67),
        (HKHex.onPrimary, HKHex.primary, 16.41),
        (HKHex.tertiary, HKHex.primary, 5.60),
        (HKHex.faint, HKHex.primary, 6.80),
        (HKHex.secondary, HKHex.primary, 3.21),
        (HKHex.onTertiary, HKHex.tertiary, 3.31),
        (HKHex.onTertiary, HKHex.tertiaryHover, 4.07),
        (HKHex.tertiary, HKHex.surface, 3.25),
        (HKHex.tertiary, HKHex.neutral, 2.93),
        (HKHex.tertiary, HKHex.tertiaryContainer, 2.84),
        (HKHex.stateKnown, HKHex.surface, 3.31),
        (HKHex.stateKnown, HKHex.kanaFill, 3.11),
        (HKHex.stateNew, HKHex.surface, 5.22),
        (HKHex.stateLearningInk, HKHex.surface, 3.75),
        (HKHex.stateLearning, HKHex.surface, 2.25),
        (HKHex.faint, HKHex.neutral, 2.41),
        (HKHex.faint, HKHex.surface, 2.68),
    ]
    for (foreground, background, documented) in pairs {
        let measured = contrast(foreground, background)
        #expect(abs(measured - documented) < 0.05, "measured \(measured), documented \(documented)")
    }
}

@Test func typographySizesMatchTheThreeColumns() throws {
    let columns: [(HKTextStyle, Int, CGFloat, CGFloat, CGFloat)] = [
        (HKFont.display, 0, 40, 56, 56),
        (HKFont.h1, 1, 30, 34, 34),
        (HKFont.h2, 2, 22, 24, 24),
        (HKFont.jpHero, 3, 72, 88, 88),
        (HKFont.jpTerm, 4, 20, 20, 18),
        (HKFont.bodyMD, 5, 15, 15, 13),
        (HKFont.bodySM, 6, 13, 13, 11),
        (HKFont.labelCaps, 7, 11, 11, 11),
        (HKFont.eyebrow, 8, 12, 12, 11),
        (HKFont.button, 9, 15, 15, 15),
    ]
    for (style, index, phone, pad, mac) in columns {
        #expect(style.size(.phone) == phone, "style \(index) phone")
        #expect(style.size(.pad) == pad, "style \(index) pad")
        #expect(style.size(.mac) == mac, "style \(index) mac")
    }
}

@Test func typographyWeightsAndLineHeightsMatchDesign() throws {
    let bold: [HKTextStyle] = [HKFont.labelCaps, HKFont.eyebrow, HKFont.button]
    let regular: [HKTextStyle] = [HKFont.display, HKFont.h1, HKFont.h2, HKFont.jpHero, HKFont.jpTerm, HKFont.bodyMD, HKFont.bodySM]
    for style in bold {
        #expect(style.weight == .bold)
    }
    for style in regular {
        #expect(style.weight == .regular)
    }
    #expect(HKFont.display.lineHeight == 1.0)
    #expect(HKFont.h1.lineHeight == 1.05)
    #expect(HKFont.h2.lineHeight == 1.1)
    #expect(HKFont.jpHero.lineHeight == 1.1)
    #expect(HKFont.jpTerm.lineHeight == 1.2)
    #expect(HKFont.bodyMD.lineHeight == 1.45)
    #expect(HKFont.bodySM.lineHeight == 1.4)
}

@Test func trackingFollowsTheEmValue() throws {
    #expect(abs(HKFont.display.tracking(.phone) - (-0.02 * 40)) < 0.001)
    #expect(abs(HKFont.display.tracking(.pad) - (-0.02 * 56)) < 0.001)
    #expect(abs(HKFont.labelCaps.tracking(.mac) - 2.2) < 0.001)
    #expect(abs(HKFont.eyebrow.tracking(.phone) - 0.24 * 12) < 0.001)
    #expect(HKFont.bodyMD.tracking(.phone) == 0)
}

@Test func lineSpacingFollowsTheLineHeight() throws {
    #expect(abs(HKFont.bodyMD.lineSpacing(.phone) - 0.45 * 15) < 0.001)
    #expect(abs(HKFont.display.lineSpacing(.phone) - 0) < 0.001)
}

@Test func layoutTokensMatchTheDesignScale() throws {
    #expect(HKSpacing.xs == 4)
    #expect(HKSpacing.sm == 8)
    #expect(HKSpacing.md == 12)
    #expect(HKSpacing.lg == 18)
    #expect(HKSpacing.xl == 24)
    #expect(HKSpacing.xxl == 40)
    #expect(HKRadius.xs == 4)
    #expect(HKRadius.sm == 10)
    #expect(HKRadius.md == 14)
    #expect(HKRadius.lg == 20)
    #expect(HKBorder.width == 1.5)
    #expect(HKBorder.hairline == 1)
    #expect(HKBorder.increased == 2)
    #expect(HKHitTarget.touchMin == 44)
    #expect(HKHitTarget.pointerMin == 28)
    #expect(HKControl.buttonTouch == 44)
    #expect(HKControl.buttonPointer == 32)
}

@Test func bundledNotoSansJPResolves() throws {
    #expect(HKFont.registerBundledFonts())
    let font = CTFontCreateWithName(HKFont.jpFamily as CFString, 12, nil)
    let postScriptName = CTFontCopyPostScriptName(font) as String
    #expect(postScriptName == HKFont.jpFamily)
}

@Test func iconsCoverEveryDocumentedSymbol() throws {
    let documented: [(AppIcon, String)] = [
        (.home, "house"),
        (.homeActive, "house.fill"),
        (.stats, "chart.bar"),
        (.statsActive, "chart.bar.fill"),
        (.settings, "gearshape"),
        (.settingsActive, "gearshape.fill"),
        (.search, "magnifyingglass"),
        (.add, "plus"),
        (.refresh, "arrow.clockwise"),
        (.close, "xmark"),
        (.chevronBack, "chevron.left"),
        (.chevronForward, "chevron.right"),
        (.ellipsis, "ellipsis"),
        (.edit, "pencil"),
        (.delete, "trash"),
        (.folder, "folder"),
        (.decks, "rectangle.stack"),
        (.keyboard, "keyboard"),
        (.skip, "forward.end"),
        (.submit, "return"),
        (.backspace, "delete.left"),
        (.correct, "checkmark"),
        (.wrong, "xmark"),
    ]
    #expect(documented.count == AppIcon.allCases.count)
    for (icon, symbol) in documented {
        #expect(icon.systemName == symbol)
    }
}

#if canImport(AppKit)
import AppKit

private func rgb(_ color: Color) -> UInt32 {
    guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return 0 }
    let red = UInt32((srgb.redComponent * 255).rounded())
    let green = UInt32((srgb.greenComponent * 255).rounded())
    let blue = UInt32((srgb.blueComponent * 255).rounded())
    return red << 16 | green << 8 | blue
}
#endif

private func contrast(_ foreground: UInt32, _ background: UInt32) -> Double {
    let one = luminance(foreground)
    let two = luminance(background)
    return (max(one, two) + 0.05) / (min(one, two) + 0.05)
}

private func luminance(_ hex: UInt32) -> Double {
    func channel(_ value: UInt32) -> Double {
        let srgb = Double(value) / 255
        return srgb <= 0.04045 ? srgb / 12.92 : pow((srgb + 0.055) / 1.055, 2.4)
    }
    let red = channel((hex >> 16) & 0xFF)
    let green = channel((hex >> 8) & 0xFF)
    let blue = channel(hex & 0xFF)
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue
}
