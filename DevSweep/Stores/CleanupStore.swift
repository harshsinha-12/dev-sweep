import Foundation
import AppKit

@MainActor
final class CleanupStore: ObservableObject {
    @Published private(set) var candidates: [CleanupCandidate] = []
    @Published private(set) var isScanning = false
    @Published private(set) var scanProgress = ScanProgress.idle
    @Published private(set) var lastReclaimedBytes: Int64 = 0
    @Published private(set) var lastCleanupSummary: String?
    @Published var searchText = ""
    @Published var selectedCategory: CleanupCategory?
    @Published var selectedConfidence: CleanupConfidence?
    @Published var sort: ScanSort = .sizeDescending
    @Published var selectedCandidateID: CleanupCandidate.ID?
    @Published var error: AppError?
    @Published var showCleanupConfirmation = false
    @Published var deletionFailures: [(url: URL, message: String)] = []

    let preferences: PreferencesStore

    private var scanTask: Task<Void, Never>?
    private let scanner: any DirectoryScanning
    private let cleanupService: any CleanupServicing

    init(
        preferences: PreferencesStore,
        scanner: any DirectoryScanning = DirectoryScanner(),
        cleanupService: any CleanupServicing = CleanupService()
    ) {
        self.preferences = preferences
        self.scanner = scanner
        self.cleanupService = cleanupService
    }

    var filteredCandidates: [CleanupCandidate] {
        var items = candidates

        if let selectedCategory {
            items = items.filter { $0.category == selectedCategory }
        }
        if let selectedConfidence {
            items = items.filter { $0.confidence == selectedConfidence }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.folderName.lowercased().contains(query)
                    || $0.projectDisplay.lowercased().contains(query)
                    || $0.pathDisplay.lowercased().contains(query)
                    || $0.category.title.lowercased().contains(query)
            }
        }

        switch sort {
        case .sizeDescending:
            items.sort { $0.sizeBytes > $1.sizeBytes }
        case .sizeAscending:
            items.sort { $0.sizeBytes < $1.sizeBytes }
        case .name:
            items.sort { $0.folderName.localizedCaseInsensitiveCompare($1.folderName) == .orderedAscending }
        case .lastModified:
            items.sort { ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast) }
        case .project:
            items.sort { $0.projectDisplay.localizedCaseInsensitiveCompare($1.projectDisplay) == .orderedAscending }
        case .category:
            items.sort { $0.category.title.localizedCaseInsensitiveCompare($1.category.title) == .orderedAscending }
        }

        return items
    }

    var totalBytes: Int64 {
        candidates.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedCandidates: [CleanupCandidate] {
        candidates.filter(\.isSelected)
    }

    var selectedBytes: Int64 {
        selectedCandidates.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedCandidate: CleanupCandidate? {
        guard let selectedCandidateID else { return nil }
        return candidates.first { $0.id == selectedCandidateID }
    }

    var categoryCounts: [(CleanupCategory, Int64)] {
        CleanupCategory.allCases.compactMap { category in
            let bytes = candidates.filter { $0.category == category }.reduce(0) { $0 + $1.sizeBytes }
            return bytes > 0 ? (category, bytes) : nil
        }
    }

    func startScan() {
        cancelScan()
        isScanning = true
        scanProgress = ScanProgress.idle
        error = nil
        lastCleanupSummary = nil

        let roots = preferences.scanRootURLs
        guard !roots.isEmpty else {
            isScanning = false
            error = .scanFailed("Add a folder to scan first. Choose where your coding projects live.")
            return
        }

        let configuration = preferences.scanConfiguration
        scanTask = Task { [weak self] in
            guard let self else { return }
            do {
                let results = try await scanner.scan(roots: roots, configuration: configuration) { [weak self] progress in
                    Task { @MainActor in
                        self?.scanProgress = progress
                    }
                }
                guard !Task.isCancelled else { return }
                candidates = results
                selectedCandidateID = results.first?.id
                isScanning = false
            } catch is CancellationError {
                isScanning = false
            } catch {
                isScanning = false
                self.error = .scanFailed(error.localizedDescription)
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        if isScanning {
            isScanning = false
            scanProgress.isCancelled = true
        }
    }

    func toggleSelection(_ id: CleanupCandidate.ID) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[index].isSelected.toggle()
    }

    func setSelection(ids: Set<CleanupCandidate.ID>, selected: Bool) {
        for index in candidates.indices {
            if ids.contains(candidates[index].id) {
                candidates[index].isSelected = selected
            }
        }
    }

    func selectAllFiltered() {
        let ids = Set(filteredCandidates.map(\.id))
        setSelection(ids: ids, selected: true)
    }

    func deselectAll() {
        for index in candidates.indices {
            candidates[index].isSelected = false
        }
    }

    func revealInFinder(_ candidate: CleanupCandidate) {
        NSWorkspace.shared.activateFileViewerSelecting([candidate.url])
    }

    func copyPath(_ candidate: CleanupCandidate) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(candidate.url.path, forType: .string)
    }

    func ignoreFolder(_ candidate: CleanupCandidate) {
        preferences.ignore(path: candidate.url)
        candidates.removeAll { $0.id == candidate.id }
        if selectedCandidateID == candidate.id {
            selectedCandidateID = candidates.first?.id
        }
    }

    func ignoreProject(_ candidate: CleanupCandidate) {
        let projectURL = candidate.url.deletingLastPathComponent()
        preferences.ignore(path: projectURL)
        candidates.removeAll {
            $0.url.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL.path
                == projectURL.resolvingSymlinksInPath().standardizedFileURL.path
        }
        selectedCandidateID = candidates.first?.id
    }

    func requestCleanup() {
        guard !selectedCandidates.isEmpty else { return }
        showCleanupConfirmation = true
    }

    func confirmCleanup() async {
        showCleanupConfirmation = false
        let selected = selectedCandidates
        let roots = preferences.scanRootURLs
        let result = await cleanupService.moveToTrash(candidates: selected, allowedRoots: roots)

        let trashedPaths = Set(result.trashed.map { $0.resolvingSymlinksInPath().standardizedFileURL.path })
        candidates.removeAll {
            trashedPaths.contains($0.url.resolvingSymlinksInPath().standardizedFileURL.path)
        }
        selectedCandidateID = candidates.first?.id
        lastReclaimedBytes = result.reclaimedBytes
        deletionFailures = result.failed

        if result.trashed.isEmpty, !result.failed.isEmpty {
            error = .deletionPartial(failed: result.failed.count, total: selected.count)
            lastCleanupSummary = nil
        } else if result.isPartialFailure {
            error = .deletionPartial(failed: result.failed.count, total: selected.count)
            lastCleanupSummary = "\(ByteFormatter.string(from: result.reclaimedBytes)) freed · \(result.trashed.count) folders moved to Trash"
        } else {
            lastCleanupSummary = "\(ByteFormatter.string(from: result.reclaimedBytes)) freed · \(result.trashed.count) folders moved to Trash"
        }
    }
}
