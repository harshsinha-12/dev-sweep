import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        List {
            Section {
                SidebarRow(
                    title: "All Results",
                    value: store.candidates.isEmpty ? nil : ByteFormatter.string(from: store.totalBytes),
                    systemImage: "square.grid.2x2",
                    selected: store.selectedCategory == nil
                ) {
                    store.selectedCategory = nil
                }

                ForEach(store.categoryCounts, id: \.0) { category, bytes in
                    SidebarRow(
                        title: category.title,
                        value: ByteFormatter.string(from: bytes),
                        systemImage: category.systemImage,
                        selected: store.selectedCategory == category
                    ) {
                        store.selectedCategory = category
                    }
                }
            } header: {
                Text("Library")
            }

            Section {
                ForEach(CleanupConfidence.allCases) { confidence in
                    SidebarRow(
                        title: confidence.title,
                        value: count(for: confidence),
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
            } header: {
                HStack {
                    Text("Safety")
                    Spacer()
                    if store.selectedConfidence != nil {
                        Button("Clear") {
                            withAnimation(.snappy) {
                                store.selectedConfidence = nil
                            }
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                ForEach(preferences.scanRootURLs, id: \.path) { root in
                    ScanRootRow(root: root) {
                        preferences.removeScanRoot(root)
                    }
                }

                Button {
                    addFolder()
                } label: {
                    Label("Add scan folder…", systemImage: "plus")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
                .foregroundStyle(DS.accent)
                .buttonStyle(.plain)
            } header: {
                HStack {
                    Text("Scan Locations")
                    Spacer()
                    Text(preferences.scanRootURLs.count.formatted())
                        .monospacedDigit()
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(DS.canvas.opacity(0.94))
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(DS.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safe cleanup")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                    Text("Files always go to Trash")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
            .padding(10)
        }
    }

    private func count(for confidence: CleanupConfidence) -> String? {
        let count = store.candidates.filter { $0.confidence == confidence }.count
        return count == 0 ? nil : count.formatted()
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
    let value: String?
    let systemImage: String
    var tint: Color = DS.accent
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 20)
                Text(title)
                    .font(.system(.callout, design: .rounded, weight: selected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Spacer(minLength: 6)
                if let value {
                    Text(value)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selected ? tint.opacity(0.16) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(selected ? tint.opacity(0.24) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
        .listRowBackground(Color.clear)
    }
}

private struct ScanRootRow: View {
    let root: URL
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .font(.system(size: 13))
                .foregroundStyle(DS.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(root.lastPathComponent)
                    .font(.system(.callout, design: .rounded, weight: .medium))
                Text(root.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 4)

            Button(action: remove) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Stop scanning this folder")
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button("Remove Scan Location", role: .destructive, action: remove)
        }
    }
}
