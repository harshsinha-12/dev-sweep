import SwiftUI

struct ScanProgressView: View {
    @EnvironmentObject private var store: CleanupStore

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .padding(22)
                    .glassEffect(.regular.interactive(), in: .circle)

                Text("Looking for leftover files…")
                    .font(.system(.title, design: .rounded, weight: .bold))

                if !store.scanProgress.currentRoot.isEmpty {
                    Text("Checking \(store.scanProgress.currentRoot)")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                GlassEffectContainer(spacing: 14) {
                    HStack(spacing: 14) {
                        metric(
                            title: "Folders checked",
                            value: store.scanProgress.directoriesChecked.formatted()
                        )
                        metric(
                            title: "Found so far",
                            value: store.scanProgress.candidatesFound.formatted()
                        )
                        metric(
                            title: "Space found",
                            value: ByteFormatter.string(from: store.scanProgress.bytesDetected)
                        )
                    }
                }

                Button("Cancel", role: .cancel) {
                    store.cancelScan()
                }
                .buttonStyle(.glass)
                .padding(.top, 4)
            }
            .padding(36)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))

            Text("This can take a minute on large project folders. You can cancel anytime.")
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
