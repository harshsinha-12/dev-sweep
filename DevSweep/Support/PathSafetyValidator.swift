import Foundation

enum PathSafetyValidator {
    /// Paths that must never be treated as cleanup candidates.
    private static let forbiddenExactPaths: Set<String> = [
        "/",
        "/Users",
        "/Applications",
        "/System",
        "/Library",
        "/private",
        "/Volumes",
        "/opt",
        "/usr",
        "/bin",
        "/sbin",
        "/etc",
        "/dev",
        "/tmp",
        "/var"
    ]

    private static let protectedHomeFolderNames: Set<String> = [
        "Documents",
        "Desktop",
        "Downloads",
        "Pictures",
        "Music",
        "Movies",
        "Library",
        "Applications",
        "Public"
    ]

    private static let neverDeleteNames: Set<String> = [
        ".git",
        ".gitignore",
        "package.json",
        "package-lock.json",
        "pnpm-lock.yaml",
        "yarn.lock",
        "Cargo.toml",
        "Cargo.lock",
        "requirements.txt",
        "pyproject.toml",
        "src",
        "Sources",
        "source"
    ]

    static func standardizedPath(for url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    static func isForbiddenExactPath(_ url: URL) -> Bool {
        let path = standardizedPath(for: url)
        if forbiddenExactPaths.contains(path) { return true }
        if path == NSHomeDirectory() { return true }

        let home = NSHomeDirectory()
        for name in protectedHomeFolderNames {
            if path == (home as NSString).appendingPathComponent(name) {
                return true
            }
        }
        return false
    }

    /// Validates that a candidate can be trashed.
    static func validateCandidate(
        _ url: URL,
        allowedRoots: [URL],
        knownSafeCachePaths: [URL] = []
    ) -> Result<URL, PathSafetyError> {
        let fm = FileManager.default
        let standardized = url.resolvingSymlinksInPath().standardizedFileURL

        guard fm.fileExists(atPath: standardized.path) else {
            return .failure(.missing(standardized.path))
        }

        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: standardized.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .failure(.notDirectory(standardized.path))
        }

        if neverDeleteNames.contains(standardized.lastPathComponent) {
            return .failure(.protectedName(standardized.lastPathComponent))
        }

        if isForbiddenExactPath(standardized) {
            return .failure(.forbiddenPath(standardized.path))
        }

        let candidatePath = standardizedPath(for: standardized)
        let rootPaths = allowedRoots.map(standardizedPath(for:))
        let safeCaches = knownSafeCachePaths.map(standardizedPath(for:))

        let insideRoot = rootPaths.contains { root in
            candidatePath == root || candidatePath.hasPrefix(root.hasSuffix("/") ? root : root + "/")
        }

        let isKnownSafeCache = safeCaches.contains { cache in
            candidatePath == cache || candidatePath.hasPrefix(cache.hasSuffix("/") ? cache : cache + "/")
        }

        guard insideRoot || isKnownSafeCache else {
            return .failure(.outsideAllowedRoots(candidatePath))
        }

        // Never allow deleting the scan root itself.
        if rootPaths.contains(candidatePath) {
            return .failure(.isScanRoot(candidatePath))
        }

        // Candidate must be a nested folder, not a top-level protected folder.
        if protectedHomeFolderNames.contains(standardized.lastPathComponent),
           standardized.deletingLastPathComponent().path == NSHomeDirectory() {
            return .failure(.forbiddenPath(candidatePath))
        }

        return .success(standardized)
    }
}

enum PathSafetyError: Error, Equatable, LocalizedError {
    case missing(String)
    case notDirectory(String)
    case protectedName(String)
    case forbiddenPath(String)
    case outsideAllowedRoots(String)
    case isScanRoot(String)

    var errorDescription: String? {
        switch self {
        case .missing(let path):
            return "\(path) no longer exists."
        case .notDirectory(let path):
            return "\(path) is not a folder."
        case .protectedName(let name):
            return "\(name) is protected and cannot be removed."
        case .forbiddenPath(let path):
            return "\(path) is not safe to remove."
        case .outsideAllowedRoots(let path):
            return "\(path) is outside your selected scan folders."
        case .isScanRoot(let path):
            return "\(path) is a scan location and cannot be removed."
        }
    }
}
