import Foundation

struct ScanConfiguration: Sendable, Equatable {
    var includeHiddenDirectories: Bool
    var includeVirtualEnvironments: Bool
    var includeBuildDirectories: Bool
    var showReviewRequired: Bool
    var minimumFolderSizeBytes: Int64
    var maxDepth: Int?
    var ignoredPaths: [URL]
    var ignoredFolderNames: Set<String>

    static let `default` = ScanConfiguration(
        includeHiddenDirectories: true,
        includeVirtualEnvironments: false,
        includeBuildDirectories: true,
        showReviewRequired: true,
        minimumFolderSizeBytes: 0,
        maxDepth: nil,
        ignoredPaths: [],
        ignoredFolderNames: []
    )
}

struct ScanProgress: Sendable, Equatable {
    var currentRoot: String
    var directoriesChecked: Int
    var candidatesFound: Int
    var bytesDetected: Int64
    var isCancelled: Bool

    static let idle = ScanProgress(
        currentRoot: "",
        directoriesChecked: 0,
        candidatesFound: 0,
        bytesDetected: 0,
        isCancelled: false
    )
}

enum ScanSort: String, CaseIterable, Identifiable, Sendable {
    case sizeDescending
    case sizeAscending
    case name
    case lastModified
    case project
    case category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sizeDescending: return "Largest first"
        case .sizeAscending: return "Smallest first"
        case .name: return "Name"
        case .lastModified: return "Recently changed"
        case .project: return "Project"
        case .category: return "Type"
        }
    }
}

struct AppPreferences: Codable, Equatable, Sendable {
    var scanRoots: [String]
    var launchScanAutomatically: Bool
    var includeHiddenDirectories: Bool
    var includeVirtualEnvironments: Bool
    var includeBuildDirectories: Bool
    var showReviewRequired: Bool
    var minimumFolderSizeBytes: Int64
    var ignoredPaths: [String]
    var ignoredFolderNames: [String]

    static let `default` = AppPreferences(
        scanRoots: [],
        launchScanAutomatically: false,
        includeHiddenDirectories: true,
        includeVirtualEnvironments: false,
        includeBuildDirectories: true,
        showReviewRequired: true,
        minimumFolderSizeBytes: 0,
        ignoredPaths: [],
        ignoredFolderNames: []
    )
}

enum AppError: LocalizedError, Identifiable, Equatable {
    case accessDenied(path: String)
    case deletionPartial(failed: Int, total: Int)
    case invalidPath(String)
    case scanFailed(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .accessDenied(let path):
            return "Could not access \(path). macOS denied permission to this directory."
        case .deletionPartial(let failed, let total):
            return "\(failed) of \(total) folders could not be moved to Trash."
        case .invalidPath(let path):
            return "\(path) is not safe to remove."
        case .scanFailed(let message):
            return message
        }
    }
}
