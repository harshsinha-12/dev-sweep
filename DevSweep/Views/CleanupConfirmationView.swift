import SwiftUI

struct CleanupConfirmationView: View {
    @EnvironmentObject private var store: CleanupStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(red: 0.25, green: 0.55, blue: 0.82))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Move to Trash?")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Nothing is permanently deleted. You can restore from Trash later.")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Space you’ll free")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(ByteFormatter.string(from: store.selectedBytes))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("\(store.selectedCandidates.count) folders")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 8) {
                Text("Folders")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.selectedCandidates) { candidate in
                            HStack {
                                Text(candidate.folderName)
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                Spacer()
                                Text(ByteFormatter.string(from: candidate.sizeBytes))
                                    .font(.system(.callout, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Text(candidate.pathDisplay)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if candidate.id != store.selectedCandidates.last?.id {
                                Divider().opacity(0.25)
                            }
                        }
                    }
                    .padding(14)
                }
                .frame(maxHeight: 220)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.glass)

                Spacer()

                Button("Move to Trash") {
                    Task {
                        await store.confirmCleanup()
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.glassProminent)
            }
        }
        .padding(28)
        .frame(width: 520)
        .background {
            AtmosphereBackground()
        }
    }
}
