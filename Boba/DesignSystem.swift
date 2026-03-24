import SwiftUI

// MARK: - Colors
extension Color {
    static let themeSurface = Color(hex: "fdf9f4")
    static let themeSurfaceContainerLow = Color(hex: "f7f3ee")
    static let themeSurfaceContainer = Color(hex: "f1ede8")
    static let themeSurfaceContainerHigh = Color(hex: "ebe8e3")
    static let themeSurfaceContainerHighest = Color(hex: "e6e2dd")
    
    static let themePrimary = Color(hex: "765928")
    static let themePrimaryContainer = Color(hex: "e1bb80")
    static let themeOnPrimaryContainer = Color(hex: "654a1a")
    static let themeOnSurface = Color(hex: "1c1c19")
    static let themeOnSurfaceVariant = Color(hex: "4e453a")
    
    static let themeSecondary = Color(hex: "765278")
    static let themeSecondaryContainer = Color(hex: "ffd1fe")
    static let themeOnSecondaryContainer = Color(hex: "7b567c")
    
    static let themeTertiary = Color(hex: "006c53")
    static let themeTertiaryContainer = Color(hex: "65d4af")
    static let themeOnTertiaryContainer = Color(hex: "005a44")
    
    static let themeError = Color(hex: "ba1a1a")
    static let themeErrorContainer = Color(hex: "ffdad6")
    static let themeOnErrorContainer = Color(hex: "93000a")
    
    static let themeOutlineVariant = Color(hex: "d1c5b5")
    static let themeBackground = Color(hex: "fdf9f4")
    
    // Gradient definitions
    static let primaryGradient = LinearGradient(
        colors: [.themePrimary, .themePrimaryContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex Initialization
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Modifiers
struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.themeSurface.opacity(0.7))
            .cornerRadius(24) // xl
            .shadow(color: Color.themeOnSurface.opacity(0.06), radius: 32, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassmorphicCard())
    }
}

// MARK: - Fonts
struct CustomFontModifier: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight
    var isHeadline: Bool
    
    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: isHeadline ? .rounded : .default))
    }
}

extension View {
    func headlineText(size: CGFloat = 24, weight: Font.Weight = .bold) -> some View {
        self.modifier(CustomFontModifier(size: size, weight: weight, isHeadline: true))
    }
    func bodyText(size: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        self.modifier(CustomFontModifier(size: size, weight: weight, isHeadline: false))
    }
}
