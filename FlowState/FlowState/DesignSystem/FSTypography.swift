import SwiftUI

enum FSTypography {
    // Display — Instrument Serif Italic
    static let displayHeroXL = Font.custom("InstrumentSerif-Italic", size: 52)
    static let displayHeroLG = Font.custom("InstrumentSerif-Italic", size: 44)
    static let displayHeroMD = Font.custom("InstrumentSerif-Italic", size: 36)

    // UI — Inter
    static let uiBody      = Font.custom("Inter-Regular", size: 14)
    static let uiBodyMedium = Font.custom("Inter-Medium", size: 14)
    static let uiLabel     = Font.custom("Inter-Medium", size: 11)
    static let uiCaption   = Font.custom("Inter-Regular", size: 12)
    static let uiSmall     = Font.custom("Inter-Regular", size: 10)
    static let uiSemibold  = Font.custom("Inter-SemiBold", size: 14)

    // Monospace — JetBrains Mono
    static let monoTimer    = Font.custom("JetBrainsMono-Bold", size: 44)
    static let monoLarge    = Font.custom("JetBrainsMono-Bold", size: 52)
    static let monoDisplay  = Font.custom("JetBrainsMono-SemiBold", size: 13)
    static let monoSmall    = Font.custom("JetBrainsMono-Medium", size: 11)
    static let monoCaption  = Font.custom("JetBrainsMono-Regular", size: 11)

    // Fallbacks using system fonts (when custom fonts aren't bundled)
    static let displayFallbackXL = Font.system(size: 52, weight: .light, design: .serif).italic()
    static let displayFallbackLG = Font.system(size: 44, weight: .light, design: .serif).italic()
    static let displayFallbackMD = Font.system(size: 36, weight: .light, design: .serif).italic()
    static let monoFallbackTimer = Font.system(size: 44, weight: .bold, design: .monospaced)
    static let monoFallbackLarge = Font.system(size: 52, weight: .bold, design: .monospaced)
}
