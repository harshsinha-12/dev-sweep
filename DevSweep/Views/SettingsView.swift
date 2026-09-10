import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        TabView {
            Form {
                Section("Startup") {
                    Toggle("Scan automatically when DevSweep opens", isOn: $preferences.preferences.launchScanAutomatically)
                }

                Section("What to look for") {
                    Toggle("Include hidden folders", isOn: $preferences.preferences.includeHiddenDirectories)
                    Toggle("Include Python virtual environments", isOn: $preferences.preferences.includeVirtualEnvironments)
                    Toggle("Include generic build folders (dist/build/out)", isOn: $preferences.preferences.includeBuildDirectories)
                    Toggle("Show “Review First” items", isOn: $preferences.preferences.showReviewRequired)
                }

                Section("Size filter") {
                    Picker("Minimum folder size", selection: $preferences.preferences.minimumFolderSizeBytes) {
                        Text("Show all").tag(Int64(0))
                        Text("1 MB or larger").tag(Int64(1_000_000))
                        Text("10 MB or larger").tag(Int64(10_000_000))
                        Text("100 MB or larger").tag(Int64(100_000_000))
                        Text("1 GB or larger").tag(Int64(1_000_000_000))
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
            .tabItem { Label("General", systemImage: "gearshape") }

            Form {
                Section("Ignored folders") {
                    if preferences.preferences.ignoredPaths.isEmpty {
                        Text("None yet. You can ignore folders from a result’s right-click menu.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(preferences.preferences.ignoredPaths, id: \.self) { path in
                            HStack {
                                Text(path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button("Remove") {
                                    preferences.removeIgnoredPath(path)
                                }
                            }
                        }
                    }
                }

                Section("Ignored folder names") {
                    if preferences.preferences.ignoredFolderNames.isEmpty {
                        Text("None yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(preferences.preferences.ignoredFolderNames, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Button("Remove") {
                                    preferences.removeIgnoredFolderName(name)
                                }
                            }
                        }
                    }

                    Button("Add Folder Name…") {
                        addIgnoredFolderName()
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
            .tabItem { Label("Ignored", systemImage: "eye.slash") }

            Form {
                Section("About safety") {
                    Text("DevSweep never uses permanent delete for normal cleanup. Selected folders are moved to Trash so you can restore them.")
                    Text("Source files, project roots, and system folders are blocked from cleanup.")
                }
                Section("Version") {
                    LabeledContent("DevSweep", value: "0.1.0")
                }
            }
            .formStyle(.grouped)
            .padding()
            .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 420)
    }

    private func addIgnoredFolderName() {
        let alert = NSAlert()
        alert.messageText = "Ignore a folder name"
        alert.informativeText = "Folders with this exact name will be skipped during scans (for example: .venv)."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        alert.accessoryView = field
        if alert.runModal() == .alertFirstButtonReturn {
            let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                preferences.ignore(folderName: name)
            }
        }
    }
}
