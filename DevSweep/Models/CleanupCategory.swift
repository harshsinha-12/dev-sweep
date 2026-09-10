import Foundation

enum CleanupCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case dependencies
    case buildCache
    case buildOutput
    case pythonCache
    case virtualEnvironment
    case xcode
    case testCoverage
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dependencies: return "Dependencies"
        case .buildCache: return "Build Caches"
        case .buildOutput: return "Build Output"
        case .pythonCache: return "Python Cache"
        case .virtualEnvironment: return "Virtual Environments"
        case .xcode: return "Xcode"
        case .testCoverage: return "Test Coverage"
        case .other: return "Other"
        }
    }

    var plainLanguage: String {
        switch self {
        case .dependencies: return "Packages your projects can download again"
        case .buildCache: return "Temporary files created while building"
        case .buildOutput: return "Finished build folders you can recreate"
        case .pythonCache: return "Python leftover cache files"
        case .virtualEnvironment: return "Python environments that can be recreated"
        case .xcode: return "Xcode build leftovers"
        case .testCoverage: return "Test report folders"
        case .other: return "Other regeneratable developer files"
        }
    }

    var systemImage: String {
        switch self {
        case .dependencies: return "shippingbox"
        case .buildCache: return "bolt.horizontal.circle"
        case .buildOutput: return "hammer"
        case .pythonCache: return "chevron.left.forwardslash.chevron.right"
        case .virtualEnvironment: return "leaf"
        case .xcode: return "xcode"
        case .testCoverage: return "checkmark.seal"
        case .other: return "folder"
        }
    }
}
