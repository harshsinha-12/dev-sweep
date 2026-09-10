import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var preferences: AppPreferences {
        didSet { save() }
    }

    private let defaultsKey = "devsweep.preferences"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppPreferences.self, from: data) {
            preferences = decoded
        } else {
            preferences = .default
            preferences.scanRoots = Self.existingDefaultRoots().map(\.path)
            save()
        }
    }

    var scanRootURLs: [URL] {
        preferences.scanRoots.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    var scanConfiguration: ScanConfiguration {
        ScanConfiguration(
            includeHiddenDirectories: preferences.includeHiddenDirectories,
            includeVirtualEnvironments: preferences.includeVirtualEnvironments,
            includeBuildDirectories: preferences.includeBuildDirectories,
            showReviewRequired: preferences.showReviewRequired,
            minimumFolderSizeBytes: preferences.minimumFolderSizeBytes,
            maxDepth: nil,
            ignoredPaths: preferences.ignoredPaths.map { URL(fileURLWithPath: $0) },
            ignoredFolderNames: Set(preferences.ignoredFolderNames)
        )
    }

    func addScanRoot(_ url: URL) {
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        guard !preferences.scanRoots.contains(path) else { return }
        preferences.scanRoots.append(path)
    }

    func removeScanRoot(_ url: URL) {
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        preferences.scanRoots.removeAll { $0 == path }
    }

    func ignore(path: URL) {
        let value = path.resolvingSymlinksInPath().standardizedFileURL.path
        guard !preferences.ignoredPaths.contains(value) else { return }
        preferences.ignoredPaths.append(value)
    }

    func ignore(folderName: String) {
        guard !preferences.ignoredFolderNames.contains(folderName) else { return }
        preferences.ignoredFolderNames.append(folderName)
    }

    func removeIgnoredPath(_ path: String) {
        preferences.ignoredPaths.removeAll { $0 == path }
    }

    func removeIgnoredFolderName(_ name: String) {
        preferences.ignoredFolderNames.removeAll { $0 == name }
    }

    static func existingDefaultRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let names = [
            "Developer",
            "Projects",
            "Documents",
            "Desktop",
            "Code",
            "Workspace",
            "Repositories"
        ]
        return names.compactMap { name in
            let url = home.appendingPathComponent(name, isDirectory: true)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
                return nil
            }
            return url
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
