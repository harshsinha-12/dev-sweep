import SwiftUI

struct ScanProgressView: View {
    @EnvironmentObject private var store: CleanupStore
    @State private var isPulsing = false

    var body: some View {
        VStack {
            Spacer(minLength: 24)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(DS.accent.opacity(0.11))
                        .frame(width: 104, height: 104)
                        .scaleEffect(isPulsing ? 1.08 : 0.94)
                        .opacity(isPulsing ? 0.55 : 1)
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.clear, DS.accent, DS.cyan, .clear],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 78, height: 78)
                        .rotationEffect(.degrees(isPulsing ? 360 : 0))
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.accent)
                }
                .glassEffect(.regular, in: .circle)

                VStack(spacing: 7) {
                    SectionEyebrow(text: "Scanning")
                    Text("Looking for space to reclaim")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    if !store.scanProgress.currentRoot.isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "folder")
                            Text(store.scanProgress.currentRoot)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 440)
                    }
                }

                HStack(spacing: 10) {
                    metric(
                        title: "Checked",
                        value: store.scanProgress.directoriesChecked.formatted(),
                        icon: "folder.badge.magnifyingglass"
                    )
                    metric(
                        title: "Found",
                        value: store.scanProgress.candidatesFound.formatted(),
                        icon: "sparkles"
                    )
                    metric(
                        title: "Reclaimable",
                        value: ByteFormatter.string(from: store.scanProgress.bytesDetected),
                        icon: "internaldrive"
                    )
                }

                Button {
                    store.cancelScan()
                } label: {
                    Label("Stop Scan", systemImage: "xmark")
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 46)
            .padding(.vertical, 38)
            .frame(maxWidth: 650)
            .glassEffect(.regular, in: .rect(cornerRadius: 30))

            Spacer(minLength: 24)
        }
        .padding(DS.pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 2.1).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }

    private func metric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.accent)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(13)
        .background(DS.insetFill, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
}
