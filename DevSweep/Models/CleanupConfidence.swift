import Foundation
import SwiftUI

enum CleanupConfidence: String, CaseIterable, Identifiable, Codable, Sendable {
    case safe
    case likelySafe
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safe: return "Safe to Remove"
        case .likelySafe: return "Likely Safe"
        case .review: return "Review First"
        }
    }

    var plainLanguage: String {
        switch self {
        case .safe: return "This is a common leftover folder. Your project can recreate it."
        case .likelySafe: return "Looks regeneratable, but take a quick look if unsure."
        case .review: return "Double-check before removing. It might be something you still need."
        }
    }

    var systemImage: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .likelySafe: return "shield.lefthalf.filled"
        case .review: return "exclamationmark.shield.fill"
        }
    }

    var tint: Color {
        switch self {
        case .safe: return Color(red: 0.18, green: 0.67, blue: 0.45)
        case .likelySafe: return Color(red: 0.95, green: 0.62, blue: 0.18)
        case .review: return Color(red: 0.92, green: 0.38, blue: 0.32)
        }
    }
}
