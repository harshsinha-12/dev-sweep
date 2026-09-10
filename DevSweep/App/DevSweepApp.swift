import SwiftUI

@main
struct DevSweepApp: App {
    @StateObject private var preferences: PreferencesStore
    @StateObject private var store: CleanupStore

    init() {
        let preferences = PreferencesStore()
        _preferences = StateObject(wrappedValue: preferences)
        _store = StateObject(wrappedValue: CleanupStore(preferences: preferences))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(preferences)
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Scan") {
                Button("Scan Again") {
                    store.startScan()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Cancel Scan") {
                    store.cancelScan()
                }
                .disabled(!store.isScanning)
            }
            CommandGroup(after: .textEditing) {
                Button("Select All Visible") {
                    store.selectAllFiltered()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Button("Deselect All") {
                    store.deselectAll()
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(preferences)
                .environmentObject(store)
        }
    }
}
