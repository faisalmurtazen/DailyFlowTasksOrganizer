import SwiftUI

struct Theme {
    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    
    // Corner radius
    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 12
    static let cornerRadiusL: CGFloat = 16
    
    // Font sizes
    static let fontSizeSmall: CGFloat = 14
    static let fontSizeMedium: CGFloat = 16
    static let fontSizeLarge: CGFloat = 20
    static let fontSizeTitle: CGFloat = 28
    static let fontSizeHero: CGFloat = 34
    
    // Shadow
    static let shadowRadius: CGFloat = 10
    static let shadowOpacity: Double = 0.1
}

// Custom view modifiers
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.spacingM)
            .background(Color.defaultSecondaryBackground)
            .cornerRadius(Theme.cornerRadiusM)
            .shadow(color: Color.black.opacity(Theme.shadowOpacity), radius: Theme.shadowRadius, x: 0, y: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

