import SwiftUI

struct CandidateRow: View {
    @EnvironmentObject private var store: CleanupStore
    let candidate: CleanupCandidate

    var body: some View {
        HStack(spacing: 14) {
            Button {
                store.toggleSelection(candidate.id)
            } label: {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        candidate.isSelected
                        ? Color(red: 0.25, green: 0.55, blue: 0.82)
                        : Color.secondary.opacity(0.7)
                    )
            }
            .buttonStyle(.plain)
            .help(candidate.isSelected ? "Deselect" : "Select")

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(candidate.folderName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    ConfidenceBadge(confidence: candidate.confidence)
                }

                Text(candidate.projectDisplay)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(candidate.pathDisplay)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 6) {
                Text(ByteFormatter.string(from: candidate.sizeBytes))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text(candidate.category.title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedCandidateID = candidate.id
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: CleanupConfidence

    var body: some View {
        Text(confidence.title)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular.tint(confidence.tint.opacity(0.45)), in: .capsule)
    }
}
