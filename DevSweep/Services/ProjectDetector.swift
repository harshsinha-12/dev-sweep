import Foundation

struct DetectionMatch: Sendable, Equatable {
    let category: CleanupCategory
    let confidence: CleanupConfidence
    let reason: String
    let projectName: String?
}

protocol ProjectDetecting: Sendable {
    func detect(at url: URL, parentProjectHints: ProjectHints) -> DetectionMatch?
    func hints(for directory: URL) -> ProjectHints
}

struct ProjectHints: Sendable, Equatable {
    var hasPackageJSON: Bool
    var hasCargoToml: Bool
    var hasPythonProject: Bool
    var hasXcodeProject: Bool
    var parentName: String

    static let empty = ProjectHints(
        hasPackageJSON: false,
        hasCargoToml: false,
        hasPythonProject: false,
        hasXcodeProject: false,
        parentName: ""
    )
}

struct ProjectDetector: ProjectDetecting {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func detect(at url: URL, parentProjectHints: ProjectHints) -> DetectionMatch? {
        let name = url.lastPathComponent
        let parent = url.deletingLastPathComponent()
        let projectName = parent.lastPathComponent

        switch name {
        case "node_modules":
            if parentProjectHints.hasPackageJSON || fileExists("package.json", in: parent) {
                return DetectionMatch(
                    category: .dependencies,
                    confidence: .safe,
                    reason: "package.json exists in the parent project",
                    projectName: projectName
                )
            }
            return DetectionMatch(
                category: .dependencies,
                confidence: .likelySafe,
                reason: "Named node_modules, a common regeneratable dependency folder",
                projectName: projectName
            )

        case ".next":
            if parentProjectHints.hasPackageJSON || fileExists("package.json", in: parent) {
                return DetectionMatch(
                    category: .buildCache,
                    confidence: .safe,
                    reason: "Next.js build output next to package.json",
                    projectName: projectName
                )
            }
            return DetectionMatch(
                category: .buildCache,
                confidence: .likelySafe,
                reason: "Named .next, typically Next.js build cache",
                projectName: projectName
            )

        case ".nuxt", ".turbo", ".parcel-cache", ".svelte-kit":
            return DetectionMatch(
                category: .buildCache,
                confidence: parentProjectHints.hasPackageJSON || fileExists("package.json", in: parent) ? .safe : .likelySafe,
                reason: "JavaScript tooling cache folder (\(name))",
                projectName: projectName
            )

        case "coverage":
            if parentProjectHints.hasPackageJSON || fileExists("package.json", in: parent) ||
                parentProjectHints.hasPythonProject {
                return DetectionMatch(
                    category: .testCoverage,
                    confidence: .likelySafe,
                    reason: "Test coverage output inside a software project",
                    projectName: projectName
                )
            }
            return nil

        case "dist", "build", "out":
            guard hasBuildEvidence(in: parent, hints: parentProjectHints) else { return nil }
            return DetectionMatch(
                category: .buildOutput,
                confidence: .review,
                reason: "Generic build folder inside a detected software project",
                projectName: projectName
            )

        case ".cache":
            guard hasBuildEvidence(in: parent, hints: parentProjectHints) else { return nil }
            return DetectionMatch(
                category: .buildCache,
                confidence: .review,
                reason: "Cache folder inside a detected software project",
                projectName: projectName
            )

        case "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache":
            return DetectionMatch(
                category: .pythonCache,
                confidence: .safe,
                reason: "Python cache that regenerates automatically",
                projectName: projectName
            )

        case ".venv", "venv":
            if parentProjectHints.hasPythonProject || hasPythonEvidence(in: parent) {
                return DetectionMatch(
                    category: .virtualEnvironment,
                    confidence: .review,
                    reason: "Python virtual environment — recreate with your usual setup command",
                    projectName: projectName
                )
            }
            return DetectionMatch(
                category: .virtualEnvironment,
                confidence: .review,
                reason: "Looks like a Python virtual environment",
                projectName: projectName
            )

        case "target":
            if parentProjectHints.hasCargoToml || fileExists("Cargo.toml", in: parent) {
                return DetectionMatch(
                    category: .buildOutput,
                    confidence: .safe,
                    reason: "Rust target folder next to Cargo.toml",
                    projectName: projectName
                )
            }
            return nil

        case "DerivedData":
            return DetectionMatch(
                category: .xcode,
                confidence: .safe,
                reason: "Xcode DerivedData cache",
                projectName: "Xcode"
            )

        default:
            return nil
        }
    }

    func hints(for directory: URL) -> ProjectHints {
        ProjectHints(
            hasPackageJSON: fileExists("package.json", in: directory),
            hasCargoToml: fileExists("Cargo.toml", in: directory),
            hasPythonProject: hasPythonEvidence(in: directory),
            hasXcodeProject: hasXcodeEvidence(in: directory),
            parentName: directory.lastPathComponent
        )
    }

    private func hasBuildEvidence(in parent: URL, hints: ProjectHints) -> Bool {
        if hints.hasPackageJSON || hints.hasCargoToml || hints.hasPythonProject || hints.hasXcodeProject {
            return true
        }
        return fileExists("package.json", in: parent)
            || fileExists("Cargo.toml", in: parent)
            || fileExists("pyproject.toml", in: parent)
            || fileExists("requirements.txt", in: parent)
            || hasXcodeEvidence(in: parent)
    }

    private func hasPythonEvidence(in directory: URL) -> Bool {
        fileExists("pyproject.toml", in: directory)
            || fileExists("requirements.txt", in: directory)
            || fileExists("setup.py", in: directory)
            || containsExtension(["py"], in: directory)
    }

    private func hasXcodeEvidence(in directory: URL) -> Bool {
        guard let items = try? fileManager.contentsOfDirectory(atPath: directory.path) else {
            return false
        }
        return items.contains { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }
    }

    private func fileExists(_ name: String, in directory: URL) -> Bool {
        fileManager.fileExists(atPath: directory.appendingPathComponent(name).path)
    }

    private func containsExtension(_ extensions: [String], in directory: URL) -> Bool {
        guard let items = try? fileManager.contentsOfDirectory(atPath: directory.path) else {
            return false
        }
        return items.contains { item in
            let ext = (item as NSString).pathExtension.lowercased()
            return extensions.contains(ext)
        }
    }
}
