import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        List {
            Section("Browse") {
                SidebarRow(
                    title: "Everything",
                    subtitle: store.candidates.isEmpty ? "All found folders" : ByteFormatter.string(from: store.totalBytes),
                    systemImage: "square.grid.2x2",
                    selected: store.selectedCategory == nil
                ) {
                    store.selectedCategory = nil
                }

                ForEach(store.categoryCounts, id: \.0) { category, bytes in
                    SidebarRow(
                        title: category.title,
                        subtitle: ByteFormatter.string(from: bytes),
                        systemImage: category.systemImage,
                        selected: store.selectedCategory == category
                    ) {
                        store.selectedCategory = category
                    }
                }
            }

            Section("Safety") {
                ForEach(CleanupConfidence.allCases) { confidence in
                    SidebarRow(
                        title: confidence.title,
                        subtitle: confidence == store.selectedConfidence ? "Showing these" : "Filter",
                        systemImage: confidence.systemImage,
                        tint: confidence.tint,
                        selected: store.selectedConfidence == confidence
                    ) {
                        if store.selectedConfidence == confidence {
                            store.selectedConfidence = nil
                        } else {
                            store.selectedConfidence = confidence
                        }
                    }
                }
            }

            Section("Folders to Scan") {
                ForEach(preferences.scanRootURLs, id: \.path) { root in
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(Color(red: 0.25, green: 0.55, blue: 0.82))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(root.lastPathComponent)
                                .font(.system(.body, design: .rounded))
                            Text(root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Button {
                            preferences.removeScanRoot(root)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove this folder")
                    }
                    .padding(.vertical, 2)
                }

                Button {
                    addFolder()
                } label: {
                    Label("Add Folder…", systemImage: "plus.circle.fill")
                        .font(.system(.body, design: .rounded, weight: .medium))
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tip")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("DevSweep only looks for leftover developer folders. Your documents and source code stay put.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .padding(12)
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        panel.message = "Choose folders that contain your coding projects."
        if panel.runModal() == .OK {
            for url in panel.urls {
                preferences.addScanRoot(url)
            }
        }
    }
}

private struct SidebarRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = Color(red: 0.25, green: 0.55, blue: 0.82)
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: selected ? .semibold : .regular))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            Group {
                if selected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular.tint(tint.opacity(0.35)), in: .rect(cornerRadius: 10))
                } else {
                    Color.clear
                }
            }
        )
    }
}
