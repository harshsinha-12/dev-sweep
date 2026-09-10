import Foundation

protocol DirectoryScanning: Sendable {
    func scan(
        roots: [URL],
        configuration: ScanConfiguration,
        progress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> [CleanupCandidate]
}

struct DirectoryScanner: DirectoryScanning {
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
        var directoriesCheckedTotal = 0
        var bytesDetectedTotal: Int64 = 0

        let ignoredPathSet = Set(configuration.ignoredPaths.map {
            $0.resolvingSymlinksInPath().standardizedFileURL.path
        })

        for root in roots {
            try Task.checkCancellation()

            let displayRoot = root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            progress(
                ScanProgress(
                    currentRoot: displayRoot,
                    directoriesChecked: directoriesCheckedTotal,
                    candidatesFound: results.count,
                    bytesDetected: bytesDetectedTotal,
                    isCancelled: false
                )
            )

            let found = try await scanRoot(
                root,
                configuration: configuration,
                ignoredPathSet: ignoredPathSet,
                baselineChecked: directoriesCheckedTotal,
                baselineCandidates: results.count,
                baselineBytes: bytesDetectedTotal,
                progress: progress
            )

            for candidate in found.candidates {
                let key = candidate.url.resolvingSymlinksInPath().standardizedFileURL.path
                if seenPaths.insert(key).inserted {
                    results.append(candidate)
                }
            }

            directoriesCheckedTotal = found.directoriesChecked
            bytesDetectedTotal = results.reduce(0) { $0 + $1.sizeBytes }

            progress(
                ScanProgress(
                    currentRoot: displayRoot,
                    directoriesChecked: directoriesCheckedTotal,
                    candidatesFound: results.count,
                    bytesDetected: bytesDetectedTotal,
                    isCancelled: false
                )
            )
        }

        let fileManager = FileManager.default
        let derivedData = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)

        if fileManager.fileExists(atPath: derivedData.path),
           !ignoredPathSet.contains(derivedData.resolvingSymlinksInPath().standardizedFileURL.path),
           !configuration.ignoredFolderNames.contains("DerivedData") {
            if let candidate = await makeCandidate(
                at: derivedData,
                hints: .empty,
                configuration: configuration
            ) {
                let key = candidate.url.resolvingSymlinksInPath().standardizedFileURL.path
                if seenPaths.insert(key).inserted {
                    results.append(candidate)
                    bytesDetectedTotal = results.reduce(0) { $0 + $1.sizeBytes }
                    progress(
                        ScanProgress(
                            currentRoot: "~/Library/Developer/Xcode/DerivedData",
                            directoriesChecked: directoriesCheckedTotal,
                            candidatesFound: results.count,
                            bytesDetected: bytesDetectedTotal,
                            isCancelled: false
                        )
                    )
                }
            }
        }

        return results.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private struct RootScanResult: Sendable {
        var candidates: [CleanupCandidate]
        var directoriesChecked: Int
    }

    private func scanRoot(
        _ root: URL,
        configuration: ScanConfiguration,
        ignoredPathSet: Set<String>,
        baselineChecked: Int,
        baselineCandidates: Int,
        baselineBytes: Int64,
        progress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> RootScanResult {
        let displayRoot = root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        let discoveredURLs = try await discoverCandidateURLs(
            root: root,
            configuration: configuration,
            ignoredPathSet: ignoredPathSet,
            baselineChecked: baselineChecked,
            baselineCandidates: baselineCandidates,
            baselineBytes: baselineBytes,
            displayRoot: displayRoot,
            progress: progress
        )

        var candidates: [CleanupCandidate] = []
        var bytesSoFar = baselineBytes

        for item in discoveredURLs.urls {
            try Task.checkCancellation()
            if let candidate = await makeCandidate(
                at: item.url,
                hints: item.hints,
                configuration: configuration
            ) {
                candidates.append(candidate)
                bytesSoFar += candidate.sizeBytes
                progress(
                    ScanProgress(
                        currentRoot: displayRoot,
                        directoriesChecked: discoveredURLs.directoriesChecked,
                        candidatesFound: baselineCandidates + candidates.count,
                        bytesDetected: bytesSoFar,
                        isCancelled: false
                    )
                )
            }
        }

        return RootScanResult(
            candidates: candidates,
            directoriesChecked: discoveredURLs.directoriesChecked
        )
    }

    private struct DiscoveredURL: Sendable {
        let url: URL
        let hints: ProjectHints
    }

    private struct DiscoveryResult: Sendable {
        let urls: [DiscoveredURL]
        let directoriesChecked: Int
    }

    private func discoverCandidateURLs(
        root: URL,
        configuration: ScanConfiguration,
        ignoredPathSet: Set<String>,
        baselineChecked: Int,
        baselineCandidates: Int,
        baselineBytes: Int64,
        displayRoot: String,
        progress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> DiscoveryResult {
        let detector = self.detector
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try Task.checkCancellation()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

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
                    continuation.resume(returning: DiscoveryResult(urls: [], directoriesChecked: baselineChecked))
                    return
                }

                var discovered: [DiscoveredURL] = []
                var directoriesChecked = baselineChecked
                var hintCache: [String: ProjectHints] = [:]

                while let item = enumerator.nextObject() as? URL {
                    if Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    directoriesChecked += 1
                    if directoriesChecked % 75 == 0 {
                        progress(
                            ScanProgress(
                                currentRoot: displayRoot,
                                directoriesChecked: directoriesChecked,
                                candidatesFound: baselineCandidates + discovered.count,
                                bytesDetected: baselineBytes,
                                isCancelled: false
                            )
                        )
                    }

                    if let maxDepth = configuration.maxDepth {
                        let relative = item.path.replacingOccurrences(of: root.path, with: "")
                        let depth = relative.split(separator: "/").count
                        if depth > maxDepth {
                            enumerator.skipDescendants()
                            continue
                        }
                    }

                    let values = try? item.resourceValues(forKeys: Set(resourceKeys))
                    if values?.isSymbolicLink == true {
                        enumerator.skipDescendants()
                        continue
                    }
                    guard values?.isDirectory == true else { continue }

                    let standardized = item.resolvingSymlinksInPath().standardizedFileURL.path
                    if ignoredPathSet.contains(standardized) {
                        enumerator.skipDescendants()
                        continue
                    }

                    let name = item.lastPathComponent
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

                    let parent = item.deletingLastPathComponent()
                    let parentKey = parent.path
                    let hints: ProjectHints
                    if let cached = hintCache[parentKey] {
                        hints = cached
                    } else {
                        let computed = detector.hints(for: parent)
                        hintCache[parentKey] = computed
                        hints = computed
                    }

                    // Only keep if detector would accept it (cheap filter before size calc).
                    if detector.detect(at: item, parentProjectHints: hints) != nil {
                        discovered.append(DiscoveredURL(url: item, hints: hints))
                        enumerator.skipDescendants()
                    }
                }

                continuation.resume(
                    returning: DiscoveryResult(urls: discovered, directoriesChecked: directoriesChecked)
                )
            }
        }
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
