import SwiftUI

struct CandidateDetailView: View {
    @EnvironmentObject private var store: CleanupStore
    let candidate: CleanupCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(candidate.folderName)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        ConfidenceBadge(confidence: candidate.confidence)
                        Text(candidate.confidence.plainLanguage)
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    detailGroup(title: "Project") {
                        Text(candidate.projectDisplay)
                            .font(.system(.body, design: .rounded, weight: .medium))
                        Text(candidate.pathDisplay)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    detailGroup(title: "Size") {
                        Text(ByteFormatter.string(from: candidate.sizeBytes))
                            .font(.system(.title, design: .rounded, weight: .bold))
                    }

                    detailGroup(title: "Last changed") {
                        Text(RelativeDateFormatter.string(from: candidate.lastModified))
                            .font(.system(.body, design: .rounded))
                    }

                    detailGroup(title: "Why we found it") {
                        Text(candidate.detectionReason)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(candidate.category.plainLanguage)
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }

            Divider().opacity(0.3)

            VStack(spacing: 10) {
                Button {
                    store.revealInFinder(candidate)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button {
                    if !candidate.isSelected {
                        store.toggleSelection(candidate.id)
                    }
                    store.requestCleanup()
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(16)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func detailGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
