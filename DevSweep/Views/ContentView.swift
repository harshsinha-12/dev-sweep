import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        ZStack {
            AppBackdrop()

            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 220, ideal: 246, max: 280)
            } detail: {
                ResultsView()
            }
            .navigationSplitViewStyle(.balanced)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    if store.isScanning {
                        Button {
                            store.cancelScan()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                        .buttonStyle(.glass)
                    }

                    Button {
                        store.startScan()
                    } label: {
                        Label(
                            store.isScanning ? "Scanning…" : "Scan Now",
                            systemImage: store.isScanning
                                ? "arrow.trianglehead.2.clockwise.rotate.90"
                                : "sparkle.magnifyingglass"
                        )
                    }
                    .buttonStyle(.glassProminent)
                    .tint(DS.accent)
                    .disabled(store.isScanning || preferences.scanRootURLs.isEmpty)
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
        }
        .searchable(
            text: $store.searchText,
            placement: .toolbar,
            prompt: "Search results"
        )
        .onKeyPress(.space) {
            if let id = store.selectedCandidateID {
                store.toggleSelection(id)
                return .handled
            }
            return .ignored
        }
        .alert(
            "Something needs attention",
            isPresented: Binding(
                get: { store.error != nil },
                set: { if !$0 { store.error = nil } }
            ),
            presenting: store.error
        ) { _ in
            Button("OK", role: .cancel) { store.error = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $store.showCleanupConfirmation) {
            CleanupConfirmationView()
                .environmentObject(store)
        }
        .onAppear {
            if preferences.preferences.launchScanAutomatically,
               !preferences.scanRootURLs.isEmpty,
               store.candidates.isEmpty,
               !store.isScanning {
                store.startScan()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CleanupStore(preferences: PreferencesStore()))
        .environmentObject(PreferencesStore())
}
