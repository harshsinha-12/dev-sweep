import SwiftUI

struct CleanupConfirmationView: View {
    @EnvironmentObject private var store: CleanupStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackdrop()

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(DS.accent.opacity(0.14))
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DS.accent)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular, in: .circle)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Review cleanup")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Items move to Trash and can be restored later.")
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionEyebrow(text: "Space to reclaim")
                        Text(ByteFormatter.string(from: store.selectedBytes))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Text("\(store.selectedCandidates.count) folders")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(DS.insetFill, in: Capsule())
                }
                .padding(18)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 8) {
                    SectionEyebrow(text: "Selected folders")

                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(store.selectedCandidates) { candidate in
                                HStack(spacing: 10) {
                                    Image(systemName: candidate.category.systemImage)
                                        .foregroundStyle(DS.accent)
                                        .frame(width: 26, height: 26)
                                        .background(DS.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.folderName)
                                            .font(.system(.callout, design: .rounded, weight: .semibold))
                                        Text(candidate.pathDisplay)
                                            .font(.system(size: 9.5, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    Spacer()
                                    Text(ByteFormatter.string(from: candidate.sizeBytes))
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(9)
                                .background(DS.insetFill, in: RoundedRectangle(cornerRadius: 11))
                            }
                        }
                        .padding(7)
                    }
                    .frame(maxHeight: 210)
                    .panelBackground(cornerRadius: 16)
                }

                HStack {
                    Label("Only these folders will be moved", systemImage: "checkmark.shield.fill")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.glass)

                    Button {
                        Task {
                            await store.confirmCleanup()
                            dismiss()
                        }
                    } label: {
                        Label("Move to Trash", systemImage: "trash")
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
                    .tint(DS.accent)
                }
            }
            .padding(26)
            .frame(width: 540)
        }
    }
}
