import Foundation

struct CleanupCandidate: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let folderName: String
    let projectName: String?
    let sizeBytes: Int64
    let lastModified: Date?
    let category: CleanupCategory
    let confidence: CleanupConfidence
    let detectionReason: String
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        folderName: String,
        projectName: String?,
        sizeBytes: Int64,
        lastModified: Date?,
        category: CleanupCategory,
        confidence: CleanupConfidence,
        detectionReason: String,
        isSelected: Bool = false
    ) {
        self.id = id
        self.url = url
        self.folderName = folderName
        self.projectName = projectName
        self.sizeBytes = sizeBytes
        self.lastModified = lastModified
        self.category = category
        self.confidence = confidence
        self.detectionReason = detectionReason
        self.isSelected = isSelected
    }

    var pathDisplay: String {
        url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    var projectDisplay: String {
        projectName ?? url.deletingLastPathComponent().lastPathComponent
    }
}
