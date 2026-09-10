import Foundation
import Testing
@testable import DevSweep

@Suite("Path safety")
struct PathSafetyValidatorTests {
    @Test("Rejects dangerous exact paths")
    func rejectsDangerousPaths() {
        let roots = [URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Developer")]
        let dangerous = [
            URL(fileURLWithPath: "/"),
            URL(fileURLWithPath: "/Users"),
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System"),
            URL(fileURLWithPath: "/Library"),
            URL(fileURLWithPath: NSHomeDirectory()),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
        ]

        for url in dangerous {
            #expect(PathSafetyValidator.isForbiddenExactPath(url))
            let result = PathSafetyValidator.validateCandidate(url, allowedRoots: roots)
            #expect(result.isFailure)
        }
    }

    @Test("Rejects scan root itself")
    func rejectsScanRoot() throws {
        let temp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let result = PathSafetyValidator.validateCandidate(temp, allowedRoots: [temp])
        guard case .failure(.isScanRoot) = result else {
            Issue.record("Expected scan root rejection, got \(result)")
            return
        }
    }

    @Test("Accepts nested node_modules inside scan root")
    func acceptsNestedCandidate() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let project = root.appendingPathComponent("my-app", isDirectory: true)
        let nodeModules = project.appendingPathComponent("node_modules", isDirectory: true)
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)

        let result = PathSafetyValidator.validateCandidate(nodeModules, allowedRoots: [root])
        #expect(result.isSuccess)
    }

    @Test("Rejects protected names")
    func rejectsProtectedNames() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let git = root.appendingPathComponent(".git", isDirectory: true)
        try FileManager.default.createDirectory(at: git, withIntermediateDirectories: true)

        let result = PathSafetyValidator.validateCandidate(git, allowedRoots: [root])
        guard case .failure(.protectedName) = result else {
            Issue.record("Expected protected name rejection")
            return
        }
    }
}

@Suite("Project detection")
struct ProjectDetectorTests {
    let detector = ProjectDetector()

    @Test("Detects node_modules with package.json")
    func detectsNodeModules() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        try " {}".write(to: root.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)
        let nodeModules = root.appendingPathComponent("node_modules", isDirectory: true)
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)

        let match = detector.detect(at: nodeModules, parentProjectHints: detector.hints(for: root))
        #expect(match?.category == .dependencies)
        #expect(match?.confidence == .safe)
    }

    @Test("Detects Rust target only with Cargo.toml")
    func detectsRustTarget() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let target = root.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)

        #expect(detector.detect(at: target, parentProjectHints: .empty) == nil)

        try "[package]".write(to: root.appendingPathComponent("Cargo.toml"), atomically: true, encoding: .utf8)
        let match = detector.detect(at: target, parentProjectHints: detector.hints(for: root))
        #expect(match?.category == .buildOutput)
        #expect(match?.confidence == .safe)
    }

    @Test("Ignores generic build without project evidence")
    func ignoresGenericBuild() {
        let url = URL(fileURLWithPath: "/tmp/random-folder/build")
        #expect(detector.detect(at: url, parentProjectHints: .empty) == nil)
    }

    @Test("Classifies Python caches as safe")
    func pythonCaches() {
        let url = URL(fileURLWithPath: "/tmp/project/__pycache__")
        let match = detector.detect(at: url, parentProjectHints: .empty)
        #expect(match?.category == .pythonCache)
        #expect(match?.confidence == .safe)
    }
}

@Suite("Formatting")
struct ByteFormatterTests {
    @Test("Formats positive sizes")
    func formatsSizes() {
        let value = ByteFormatter.string(from: 4_700_000_000)
        #expect(value.contains("GB") || value.contains("gigabyte"))
        #expect(ByteFormatter.string(from: 0) == "0 KB")
    }
}

@Suite("Scanner")
struct DirectoryScannerTests {
    @Test("Finds node_modules and skips project root")
    func findsCandidates() async throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let project = root.appendingPathComponent("site", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        try "{}".write(to: project.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)

        let nodeModules = project.appendingPathComponent("node_modules", isDirectory: true)
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        try "module".write(to: nodeModules.appendingPathComponent("file.txt"), atomically: true, encoding: .utf8)

        let scanner = DirectoryScanner()
        let results = try await scanner.scan(roots: [root], configuration: .default) { _ in }

        #expect(results.contains { $0.folderName == "node_modules" })
        #expect(!results.contains { $0.url == root })
        #expect(!results.contains { $0.url == project })
    }
}

private extension Result {
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

private func makeTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("DevSweepTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
