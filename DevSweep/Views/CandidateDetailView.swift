import SwiftUI

struct CandidateDetailView: View {
    @EnvironmentObject private var store: CleanupStore
    let candidate: CleanupCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionEyebrow(text: "Inspector")
                Spacer()
                Menu {
                    Button("Reveal in Finder") {
                        store.revealInFinder(candidate)
                    }
                    Button("Copy Path") {
                        store.copyPath(candidate)
                    }
                    Divider()
                    Button("Ignore Folder") {
                        store.ignoreFolder(candidate)
                    }
                    Button("Ignore Project") {
                        store.ignoreProject(candidate)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 10) {
                            Image(systemName: candidate.category.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(DS.accent)
                                .frame(width: 40, height: 40)
                                .background(DS.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(candidate.folderName)
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .lineLimit(1)
                                Text(candidate.category.title)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ConfidenceBadge(confidence: candidate.confidence)
                            .padding(.top, 3)

                        Text(candidate.confidence.plainLanguage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        detailRow(
                            title: "Project",
                            value: candidate.projectDisplay,
                            icon: "folder"
                        )
                        Divider().padding(.leading, 32)
                        detailRow(
                            title: "Size",
                            value: ByteFormatter.string(from: candidate.sizeBytes),
                            icon: "externaldrive"
                        )
                        Divider().padding(.leading, 32)
                        detailRow(
                            title: "Last changed",
                            value: RelativeDateFormatter.string(from: candidate.lastModified),
                            icon: "clock"
                        )
                    }
                    .background(DS.insetFill, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 7) {
                        SectionEyebrow(text: "Why it appeared")
                        Text(candidate.detectionReason)
                            .font(.system(.callout, design: .rounded, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(candidate.category.plainLanguage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(13)
                    .background(DS.insetFill, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 6) {
                        SectionEyebrow(text: "Location")
                        Text(candidate.pathDisplay)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
            }

            Divider().opacity(0.35)

            HStack(spacing: 8) {
                Button {
                    store.revealInFinder(candidate)
                } label: {
                    Label("Finder", systemImage: "folder")
                }
                .buttonStyle(.glass)

                Button {
                    if !candidate.isSelected {
                        store.toggleSelection(candidate.id)
                    }
                    store.requestCleanup()
                } label: {
                    Label("Review", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(DS.accent)
            }
            .padding(12)
        }
        .frame(maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: DS.contentCornerRadius))
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }
}
