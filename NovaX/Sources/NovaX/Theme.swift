import SwiftUI

// MARK: - NovaX Palette (mirrors com.novax.app.ui.theme.Color)

enum NovaTheme {
    // Common
    static let primaryPurple   = Color(hex: 0x8B5CF6)   // Modern Purple
    static let secondaryPurple = Color(hex: 0x6D28D9)   // Deep Purple
    static let accentPurple    = Color(hex: 0xA78BFA)   // Soft Purple

    // Dark Mode
    static let darkBackground     = Color(hex: 0x000000)
    static let darkSurface        = Color(hex: 0x0D0D0D)
    static let darkCard           = Color(hex: 0x141414)
    static let darkBorder         = Color(hex: 0x222222)
    static let darkTextPrimary    = Color(hex: 0xFFFFFF)
    static let darkTextSecondary  = Color(hex: 0x9CA3AF)

    // Light Mode
    static let lightBackground    = Color(hex: 0xFFFFFF)
    static let lightSurface       = Color(hex: 0xF9FAFB)
    static let lightCard          = Color(hex: 0xFFFFFF)
    static let lightBorder        = Color(hex: 0xE5E7EB)
    static let lightTextPrimary   = Color(hex: 0x111827)
    static let lightTextSecondary = Color(hex: 0x4B5563)

    // Status
    static let statusGreen  = Color(hex: 0x10B981)
    static let statusYellow = Color(hex: 0xFBBF24)
    static let statusRed    = Color(hex: 0xEF4444)
}

// MARK: - Resolved palette per theme (dark/light)

struct NovaPalette {
    let background: Color
    let surface: Color
    let card: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color

    static let dark = NovaPalette(
        background: NovaTheme.darkBackground,
        surface: NovaTheme.darkSurface,
        card: NovaTheme.darkCard,
        border: NovaTheme.darkBorder,
        textPrimary: NovaTheme.darkTextPrimary,
        textSecondary: NovaTheme.darkTextSecondary
    )

    static let light = NovaPalette(
        background: NovaTheme.lightBackground,
        surface: NovaTheme.lightSurface,
        card: NovaTheme.lightCard,
        border: NovaTheme.lightBorder,
        textPrimary: NovaTheme.lightTextPrimary,
        textSecondary: NovaTheme.lightTextSecondary
    )

    static func current(_ dark: Bool) -> NovaPalette { dark ? .dark : .light }

    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [NovaTheme.primaryPurple, NovaTheme.secondaryPurple],
            startPoint: .leading, endPoint: .trailing
        )
    }
}

// MARK: - Environment key so views can read palette

private struct NovaPaletteKey: EnvironmentKey {
    static let defaultValue = NovaPalette.dark
}

extension EnvironmentValues {
    var nova: NovaPalette {
        get { self[NovaPaletteKey.self] }
        set { self[NovaPaletteKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
