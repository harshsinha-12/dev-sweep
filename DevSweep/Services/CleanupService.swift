import Foundation

struct CleanupResult: Sendable, Equatable {
    var trashed: [URL]
    var failed: [(url: URL, message: String)]
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
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func moveToTrash(
        candidates: [CleanupCandidate],
        allowedRoots: [URL]
    ) async -> CleanupResult {
        let derivedData = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)

        var trashed: [URL] = []
        var failed: [(URL, String)] = []
        var reclaimed: Int64 = 0

        for candidate in candidates {
            let validation = PathSafetyValidator.validateCandidate(
                candidate.url,
                allowedRoots: allowedRoots,
                knownSafeCachePaths: [derivedData]
            )

            switch validation {
            case .failure(let error):
                failed.append((candidate.url, error.localizedDescription))
            case .success(let safeURL):
                // Re-verify name still matches the candidate we detected.
                guard safeURL.lastPathComponent == candidate.folderName else {
                    failed.append((candidate.url, "Folder name no longer matches the detected item."))
                    continue
                }

                do {
                    var resultingURL: NSURL?
                    try fileManager.trashItem(at: safeURL, resultingItemURL: &resultingURL)
                    trashed.append(safeURL)
                    reclaimed += candidate.sizeBytes
                } catch {
                    failed.append((candidate.url, error.localizedDescription))
                }
            }
        }

        return CleanupResult(trashed: trashed, failed: failed, reclaimedBytes: reclaimed)
    }
}
