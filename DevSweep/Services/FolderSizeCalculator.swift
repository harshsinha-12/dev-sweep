import Foundation

protocol FolderSizeCalculating: Sendable {
    func size(of url: URL) async -> Int64
}

struct FolderSizeCalculator: FolderSizeCalculating {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func size(of url: URL) async -> Int64 {
        await Task.detached(priority: .utility) {
            Self.calculateSize(of: url, fileManager: .default)
        }.value
    }

    nonisolated static func calculateSize(of url: URL, fileManager: FileManager = .default) -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey,
            .fileSizeKey,
            .isPackageKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }

        var total: Int64 = 0
        let rootPath = url.resolvingSymlinksInPath().standardizedFileURL.path

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: resourceKeys)

                if values.isSymbolicLink == true {
                    // Do not follow symlinks outside the traversal tree.
                    enumerator.skipDescendants()
                    continue
                }

                let standardized = fileURL.standardizedFileURL.path
                if !standardized.hasPrefix(rootPath) {
                    enumerator.skipDescendants()
                    continue
                }

                if values.isDirectory == true {
                    continue
                }

                if let allocated = values.totalFileAllocatedSize {
                    total += Int64(allocated)
                } else if let allocated = values.fileAllocatedSize {
                    total += Int64(allocated)
                } else if let size = values.fileSize {
                    total += Int64(size)
                }
            } catch {
                continue
            }
        }

        return total
    }
}
