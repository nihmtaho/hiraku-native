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
        (HKHex.onTertiary, HKHex.tertiary, 3.31),
        (HKHex.stateKnown, HKHex.surface, 3.31),
        (HKHex.stateNew, HKHex.surface, 5.22),
        (HKHex.stateLearningInk, HKHex.surface, 3.75),
        (HKHex.stateLearning, HKHex.surface, 2.25),
    ]
    for (foreground, background, documented) in pairs {
        let measured = contrast(foreground, background)
        #expect(abs(measured - documented) < 0.05, "measured \(measured), documented \(documented)")
    }
}

@Test func typographyMatchesThePlatformColumn() throws {
    #if os(macOS)
    #expect(HKFont.display.size == 56)
    #expect(HKFont.h1.size == 34)
    #expect(HKFont.h2.size == 24)
    #expect(HKFont.jpHero.size == 88)
    #expect(HKFont.jpTerm.size == 18)
    #expect(HKFont.bodyMD.size == 13)
    #expect(HKFont.bodySM.size == 11)
    #expect(HKFont.eyebrow.size == 11)
    #expect(HKFont.button.size == 13)
    #else
    #expect(HKFont.display.size == 40)
    #expect(HKFont.h1.size == 30)
    #expect(HKFont.h2.size == 22)
    #expect(HKFont.jpHero.size == 72)
    #expect(HKFont.jpTerm.size == 20)
    #expect(HKFont.bodyMD.size == 15)
    #expect(HKFont.bodySM.size == 13)
    #expect(HKFont.eyebrow.size == 12)
    #expect(HKFont.button.size == 15)
    #endif
    #expect(HKFont.labelCaps.size == 11)
}

@Test func trackingFollowsTheEmValue() throws {
    #expect(abs(HKFont.display.tracking - (-0.02 * HKFont.display.size)) < 0.001)
    #expect(abs(HKFont.labelCaps.tracking - 2.2) < 0.001)
    #expect(abs(HKFont.eyebrow.tracking - 0.24 * HKFont.eyebrow.size) < 0.001)
    #expect(HKFont.bodyMD.tracking == 0)
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
    #expect(HKHitTarget.touchMin == 44)
    #expect(HKHitTarget.pointerMin == 28)
}

@Test func bundledNotoSansJPResolves() throws {
    #expect(HKFont.registerBundledFonts())
    let font = CTFontCreateWithName(HKFont.jpFamily as CFString, 12, nil)
    let postScriptName = CTFontCopyPostScriptName(font) as String
    #expect(postScriptName == HKFont.jpFamily)
}

@Test func iconsCoverTheDocumentedSymbols() throws {
    let documented: [(AppIcon, String)] = [
        (.home, "house"),
        (.homeActive, "house.fill"),
        (.stats, "chart.bar"),
        (.settings, "gearshape"),
        (.search, "magnifyingglass"),
        (.add, "plus"),
        (.chevronBack, "chevron.left"),
        (.keyboard, "keyboard"),
        (.submit, "return"),
        (.backspace, "delete.left"),
        (.correct, "checkmark"),
        (.wrong, "xmark"),
    ]
    for (icon, symbol) in documented {
        #expect(icon.systemName == symbol)
    }
    #expect(AppIcon.allCases.allSatisfy { !$0.systemName.isEmpty })
}

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
