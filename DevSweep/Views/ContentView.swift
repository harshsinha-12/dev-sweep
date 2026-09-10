import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        ZStack {
            AtmosphereBackground()

            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
            } detail: {
                ResultsView()
            }
            .navigationSplitViewStyle(.balanced)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 10) {
                        if store.isScanning {
                            Button("Cancel", role: .cancel) {
                                store.cancelScan()
                            }
                            .buttonStyle(.glass)
                        }

                        Button {
                            store.startScan()
                        } label: {
                            Label(store.isScanning ? "Scanning…" : "Scan", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(store.isScanning || preferences.scanRootURLs.isEmpty)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                }
            }
        }
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "Search folders or projects")
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

struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.96, blue: 0.98),
                    Color(red: 0.86, green: 0.91, blue: 0.96),
                    Color(red: 0.91, green: 0.94, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.45, green: 0.72, blue: 0.92).opacity(0.28))
                .frame(width: 420, height: 420)
                .blur(radius: 50)
                .offset(x: -280, y: -220)

            Circle()
                .fill(Color(red: 0.55, green: 0.82, blue: 0.68).opacity(0.22))
                .frame(width: 380, height: 380)
                .blur(radius: 60)
                .offset(x: 320, y: 180)

            Circle()
                .fill(Color(red: 0.98, green: 0.78, blue: 0.45).opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: 160, y: -160)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environmentObject(CleanupStore(preferences: PreferencesStore()))
        .environmentObject(PreferencesStore())
}
