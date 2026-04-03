/**
 DesignSystem.swift
 
 Centralized design tokens and view modifiers for consistent theming across the app.
 - Defines palette colors and gradients
 - Provides a hex-based Color initializer
 - Adds reusable glassmorphic card and typography helpers
 
 Last Updated: April 2, 2026
 */
import SwiftUI

// Color palette tokens for surfaces, content, and states
// MARK: - Colors
extension Color {
    // Surface scale (background layers)
    static let themeSurface = Color(hex: "fdf9f4")
    static let themeSurfaceContainerLow = Color(hex: "f7f3ee")
    static let themeSurfaceContainer = Color(hex: "f1ede8")
    static let themeSurfaceContainerHigh = Color(hex: "ebe8e3")
    static let themeSurfaceContainerHighest = Color(hex: "e6e2dd")
    
    // Primary color family
    static let themePrimary = Color(hex: "765928")
    static let themePrimaryContainer = Color(hex: "e1bb80")
    static let themeOnPrimaryContainer = Color(hex: "654a1a")
    static let themeOnSurface = Color(hex: "1c1c19")
    static let themeOnSurfaceVariant = Color(hex: "4e453a")
    
    // Secondary color family
    static let themeSecondary = Color(hex: "765278")
    static let themeSecondaryContainer = Color(hex: "ffd1fe")
    static let themeOnSecondaryContainer = Color(hex: "7b567c")
    
    // Tertiary color family
    static let themeTertiary = Color(hex: "006c53")
    static let themeTertiaryContainer = Color(hex: "65d4af")
    static let themeOnTertiaryContainer = Color(hex: "005a44")
    
    // Error colors
    static let themeError = Color(hex: "ba1a1a")
    static let themeErrorContainer = Color(hex: "ffdad6")
    static let themeOnErrorContainer = Color(hex: "93000a")
    
    // Misc tokens
    static let themeOutlineVariant = Color(hex: "d1c5b5")
    static let themeBackground = Color(hex: "fdf9f4")
    
    // Brand gradient used for accents and backgrounds
    static let primaryGradient = LinearGradient(
        colors: [.themePrimary, .themePrimaryContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Mood colors
    static let moodTerrible = Color(hex: "ffcac8")
    static let moodBad = Color(hex: "fbcfb5")
    static let moodOkay = Color(hex: "efd5ad")
    static let moodGood = Color(hex: "e2dbad")
    static let moodGreat = Color(hex: "d2e0b4")
}

// Utility to construct Color values from hex strings (RGB/ARGB)
// MARK: - Hex Initialization
extension Color {
    // Initialize from hex strings like "FFFFFF", "#FFFFFF", or "FF00FF80"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        // Support common hex lengths: 3, 6, and 8 (ARGB)
        switch hex.count {
        // RGB (12-bit)
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        // RGB (24-bit)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        // ARGB (32-bit)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        // Fallback to a fully transparent value if parsing fails
        default:
            #if DEBUG
            assertionFailure("Invalid hex string: \(hex)")
            #endif
            (a, r, g, b) = (0, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Design tokens for spacing, radii, and shadows
// MARK: - Tokens
enum DS {
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    enum Shadow {
        static let card = (color: Color.themeOnSurface.opacity(0.06), radius: 32.0, x: 0.0, y: 12.0)
    }
}

// Reusable view modifiers for consistent components
// MARK: - Modifiers

// Liquid Glass card appearance with interactive tint and subtle stroke
struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Apply Liquid Glass effect with interactive tint and rounded rect shape
            .glassEffect(.regular.tint(Color.themeSurface.opacity(0.2)).interactive(), in: .rect(cornerRadius: DS.Radius.lg))
            // Soft drop shadow for elevation
            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: DS.Shadow.card.x, y: DS.Shadow.card.y)
            // Subtle inner stroke for definition
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Convenience API to apply the glass card style
extension View {
    func glassCard() -> some View {
        self.modifier(GlassmorphicCard())
    }
}

// Convenience container for grouping multiple Liquid Glass elements and enabling blending
struct GlassContainer<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = DS.Spacing.lg, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}

// Typography helpers for consistent text styling
// MARK: - Fonts

// Dynamic Type-friendly text style modifier
struct TextStyleModifier: ViewModifier {
    var style: Font.TextStyle
    var weight: Font.Weight
    var rounded: Bool

    func body(content: Content) -> some View {
        content.font(.system(style, design: rounded ? .rounded : .default).weight(weight))
    }
}

// Convenience functions for text styles that scale with Dynamic Type
extension View {
    func headlineTextStyle(weight: Font.Weight = .bold) -> some View {
        self.modifier(TextStyleModifier(style: .title2, weight: weight, rounded: true))
    }
    func bodyTextStyle(weight: Font.Weight = .regular) -> some View {
        self.modifier(TextStyleModifier(style: .body, weight: weight, rounded: false))
    }
}

// Parameterized font modifier supporting headline/body variants
struct CustomFontModifier: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight
    var isHeadline: Bool
    
    func body(content: Content) -> some View {
        // Use rounded design for headlines, system default for body
        content.font(.system(size: size, weight: weight, design: isHeadline ? .rounded : .default))
    }
}

// Convenience functions for common text styles
extension View {
    func headlineText(size: CGFloat = 24, weight: Font.Weight = .bold) -> some View {
        self.modifier(CustomFontModifier(size: size, weight: weight, isHeadline: true))
    }
    func bodyText(size: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        self.modifier(CustomFontModifier(size: size, weight: weight, isHeadline: false))
    }
}

