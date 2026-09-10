import SwiftUI

struct CandidateRow: View {
    @EnvironmentObject private var store: CleanupStore
    let candidate: CleanupCandidate
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    store.toggleSelection(candidate.id)
                }
            } label: {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        candidate.isSelected
                            ? DS.accent
                            : Color.secondary.opacity(isHovering ? 0.9 : 0.55)
                    )
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help(candidate.isSelected ? "Deselect" : "Select")

            Image(systemName: candidate.category.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(categoryTint)
                .frame(width: 34, height: 34)
                .background(categoryTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(candidate.folderName)
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .lineLimit(1)
                    ConfidenceBadge(confidence: candidate.confidence)
                }

                HStack(spacing: 5) {
                    Text(candidate.projectDisplay)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text(candidate.pathDisplay)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(ByteFormatter.string(from: candidate.sizeBytes))
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text(candidate.category.title)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 92, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(
                    store.selectedCandidateID == candidate.id
                        ? DS.accent.opacity(0.40)
                        : Color.primary.opacity(isHovering ? 0.08 : 0.035),
                    lineWidth: store.selectedCandidateID == candidate.id ? 1.25 : 0.75
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) {
                store.selectedCandidateID = candidate.id
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    private var rowFill: Color {
        if store.selectedCandidateID == candidate.id {
            return DS.accent.opacity(0.10)
        }
        if isHovering {
            return Color.primary.opacity(0.055)
        }
        return Color.primary.opacity(0.025)
    }

    private var categoryTint: Color {
        switch candidate.category {
        case .dependencies: return DS.accent
        case .buildCache: return DS.cyan
        case .buildOutput: return DS.amber
        case .pythonCache, .virtualEnvironment: return DS.mint
        case .xcode: return Color(red: 0.20, green: 0.65, blue: 0.96)
        case .testCoverage: return Color(red: 0.52, green: 0.72, blue: 0.28)
        case .other: return .secondary
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: CleanupConfidence

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidence.tint)
                .frame(width: 5, height: 5)
            Text(shortTitle)
        }
        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
        .foregroundStyle(confidence.tint)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(confidence.tint.opacity(0.11), in: Capsule())
        .overlay(Capsule().strokeBorder(confidence.tint.opacity(0.22)))
    }

    private var shortTitle: String {
        switch confidence {
        case .safe: return "Safe"
        case .likelySafe: return "Likely Safe"
        case .review: return "Review"
        }
    }
}
