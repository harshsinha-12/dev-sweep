import Foundation

protocol DirectoryScanning: Sendable {
    func scan(
        roots: [URL],
        configuration: ScanConfiguration,
        progress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> [CleanupCandidate]
}

actor DirectoryScanner: DirectoryScanning {
    private let detector: any ProjectDetecting
    private let sizeCalculator: any FolderSizeCalculating

    private static let candidateNames: Set<String> = [
        "node_modules",
        ".next",
        ".nuxt",
        ".turbo",
        ".parcel-cache",
        ".svelte-kit",
        "coverage",
        "dist",
        "build",
        "out",
        ".cache",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
        ".ruff_cache",
        ".venv",
        "venv",
        "target",
        "DerivedData"
    ]

    init(
        detector: any ProjectDetecting = ProjectDetector(),
        sizeCalculator: any FolderSizeCalculating = FolderSizeCalculator()
    ) {
        self.detector = detector
        self.sizeCalculator = sizeCalculator
    }

    func scan(
        roots: [URL],
        configuration: ScanConfiguration,
        progress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> [CleanupCandidate] {
        var results: [CleanupCandidate] = []
        var seenPaths = Set<String>()
        var state = ScanProgress.idle

        let ignoredPathSet = Set(configuration.ignoredPaths.map {
            $0.resolvingSymlinksInPath().standardizedFileURL.path
        })

        for root in roots {
            if Task.isCancelled {
                state.isCancelled = true
                progress(state)
                break
            }

            state.currentRoot = root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            progress(state)

            let found = await scanRoot(
                root,
                configuration: configuration,
                ignoredPathSet: ignoredPathSet,
                progress: { update in
                    state.directoriesChecked = update.directoriesChecked
                    state.candidatesFound = results.count + update.candidatesFound
                    state.bytesDetected = results.reduce(0) { $0 + $1.sizeBytes } + update.bytesDetected
                    progress(state)
                }
            )

            for candidate in found {
                let key = candidate.url.resolvingSymlinksInPath().standardizedFileURL.path
                if seenPaths.insert(key).inserted {
                    results.append(candidate)
                }
            }

            state.candidatesFound = results.count
            state.bytesDetected = results.reduce(0) { $0 + $1.sizeBytes }
            progress(state)
        }

        let fileManager = FileManager.default

        // Always include common Xcode DerivedData if present and not ignored.
        let derivedData = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
        if fileManager.fileExists(atPath: derivedData.path),
           !ignoredPathSet.contains(derivedData.resolvingSymlinksInPath().standardizedFileURL.path),
           !configuration.ignoredFolderNames.contains("DerivedData") {
            if let candidate = await makeCandidate(at: derivedData, hints: .empty, configuration: configuration) {
                let key = candidate.url.resolvingSymlinksInPath().standardizedFileURL.path
                if seenPaths.insert(key).inserted {
                    results.append(candidate)
                    state.candidatesFound = results.count
                    state.bytesDetected = results.reduce(0) { $0 + $1.sizeBytes }
                    progress(state)
                }
            }
        }

        return results.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func scanRoot(
        _ root: URL,
        configuration: ScanConfiguration,
        ignoredPathSet: Set<String>,
        progress: @Sendable @escaping (ScanProgress) -> Void
    ) async -> [CleanupCandidate] {
        var candidates: [CleanupCandidate] = []
        var directoriesChecked = 0
        var bytesDetected: Int64 = 0
        let fileManager = FileManager.default

        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .contentModificationDateKey,
            .isHiddenKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: resourceKeys,
            options: configuration.includeHiddenDirectories ? [] : [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return []
        }

        var hintCache: [String: ProjectHints] = [:]

        for case let itemURL as URL in enumerator {
            if Task.isCancelled { break }

            directoriesChecked += 1
            if directoriesChecked % 50 == 0 {
                progress(
                    ScanProgress(
                        currentRoot: root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                        directoriesChecked: directoriesChecked,
                        candidatesFound: candidates.count,
                        bytesDetected: bytesDetected,
                        isCancelled: false
                    )
                )
                await Task.yield()
            }

            if let maxDepth = configuration.maxDepth {
                let relative = itemURL.path.replacingOccurrences(of: root.path, with: "")
                let depth = relative.split(separator: "/").count
                if depth > maxDepth {
                    enumerator.skipDescendants()
                    continue
                }
            }

            let values = try? itemURL.resourceValues(forKeys: Set(resourceKeys))
            if values?.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            guard values?.isDirectory == true else { continue }

            let standardized = itemURL.resolvingSymlinksInPath().standardizedFileURL.path
            if ignoredPathSet.contains(standardized) {
                enumerator.skipDescendants()
                continue
            }

            let name = itemURL.lastPathComponent
            if configuration.ignoredFolderNames.contains(name) {
                enumerator.skipDescendants()
                continue
            }

            guard Self.candidateNames.contains(name) else { continue }

            if name == ".venv" || name == "venv", !configuration.includeVirtualEnvironments {
                enumerator.skipDescendants()
                continue
            }

            if ["dist", "build", "out"].contains(name), !configuration.includeBuildDirectories {
                enumerator.skipDescendants()
                continue
            }

            let parent = itemURL.deletingLastPathComponent()
            let parentKey = parent.path
            let hints: ProjectHints
            if let cached = hintCache[parentKey] {
                hints = cached
            } else {
                let computed = detector.hints(for: parent)
                hintCache[parentKey] = computed
                hints = computed
            }

            if let candidate = await makeCandidate(at: itemURL, hints: hints, configuration: configuration) {
                candidates.append(candidate)
                bytesDetected += candidate.sizeBytes
                // Do not descend into candidate folders (e.g. node_modules internals).
                enumerator.skipDescendants()
            }
        }

        progress(
            ScanProgress(
                currentRoot: root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                directoriesChecked: directoriesChecked,
                candidatesFound: candidates.count,
                bytesDetected: bytesDetected,
                isCancelled: Task.isCancelled
            )
        )

        return candidates
    }

    private func makeCandidate(
        at url: URL,
        hints: ProjectHints,
        configuration: ScanConfiguration
    ) async -> CleanupCandidate? {
        guard let match = detector.detect(at: url, parentProjectHints: hints) else {
            return nil
        }

        if match.confidence == .review, !configuration.showReviewRequired {
            return nil
        }

        let size = await sizeCalculator.size(of: url)
        if size < configuration.minimumFolderSizeBytes {
            return nil
        }

        let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate

        return CleanupCandidate(
            url: url,
            folderName: url.lastPathComponent,
            projectName: match.projectName,
            sizeBytes: size,
            lastModified: modified,
            category: match.category,
            confidence: match.confidence,
            detectionReason: match.reason
        )
    }
}
