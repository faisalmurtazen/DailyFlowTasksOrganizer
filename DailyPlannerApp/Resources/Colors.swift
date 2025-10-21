import SwiftUI

extension Color {
    // Primary colors
    static let primaryBackground = Color("PrimaryBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let accentTeal = Color("AccentTeal")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // Default fallback colors
    static let defaultPrimaryBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1) : .white
    })
    
    static let defaultSecondaryBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 0.95, alpha: 1)
    })
    
    static let defaultAccentTeal = Color(red: 0.3, green: 0.7, blue: 0.7)
    
    static let defaultTextPrimary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .white : .black
    })
    
    static let defaultTextSecondary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.7, alpha: 1) : UIColor(white: 0.4, alpha: 1)
    })
}

