import Foundation

struct CleanupFailure: Sendable, Equatable {
    let url: URL
    let message: String
}

struct CleanupResult: Sendable, Equatable {
    var trashed: [URL]
    var failed: [CleanupFailure]
    var reclaimedBytes: Int64

    var isPartialFailure: Bool { !failed.isEmpty }
}

protocol CleanupServicing: Sendable {
    func moveToTrash(
        candidates: [CleanupCandidate],
        allowedRoots: [URL]
    ) async -> CleanupResult
}

struct CleanupService: CleanupServicing {
    func moveToTrash(
        candidates: [CleanupCandidate],
        allowedRoots: [URL]
    ) async -> CleanupResult {
        let fileManager = FileManager.default
        let derivedData = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)

        var trashed: [URL] = []
        var failed: [CleanupFailure] = []
        var reclaimed: Int64 = 0

        for candidate in candidates {
            let validation = PathSafetyValidator.validateCandidate(
                candidate.url,
                allowedRoots: allowedRoots,
                knownSafeCachePaths: [derivedData]
            )

            switch validation {
            case .failure(let error):
                failed.append(CleanupFailure(url: candidate.url, message: error.localizedDescription))
            case .success(let safeURL):
                guard safeURL.lastPathComponent == candidate.folderName else {
                    failed.append(
                        CleanupFailure(
                            url: candidate.url,
                            message: "Folder name no longer matches the detected item."
                        )
                    )
                    continue
                }

                do {
                    var resultingURL: NSURL?
                    try fileManager.trashItem(at: safeURL, resultingItemURL: &resultingURL)
                    trashed.append(safeURL)
                    reclaimed += candidate.sizeBytes
                } catch {
                    failed.append(CleanupFailure(url: candidate.url, message: error.localizedDescription))
                }
            }
        }

        return CleanupResult(trashed: trashed, failed: failed, reclaimedBytes: reclaimed)
    }
}
