import SwiftUI

extension Color {
    static var cardBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }
}
