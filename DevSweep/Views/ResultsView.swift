import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        VStack(spacing: 0) {
            if store.isScanning {
                ScanProgressView()
                    .padding(20)
            } else if store.candidates.isEmpty {
                if store.hasCompletedScan {
                    CleanEmptyStateView()
                } else {
                    EmptyStateView()
                }
            } else {
                resultsContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            if !store.selectedCandidates.isEmpty {
                CleanupActionBar()
            }
        }
    }

    private var resultsContent: some View {
        VStack(spacing: 16) {
            heroHeader
                .padding(.horizontal, 20)
                .padding(.top, 20)

            controls
                .padding(.horizontal, 20)

            if let summary = store.lastCleanupSummary {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.18, green: 0.67, blue: 0.45))
                    Text(summary)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    Spacer()
                }
                .padding(14)
                .glassEffect(.regular.tint(Color(red: 0.18, green: 0.67, blue: 0.45).opacity(0.25)), in: .rect(cornerRadius: 14))
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(alignment: .top, spacing: 16) {
                candidateList
                if let candidate = store.selectedCandidate {
                    CandidateDetailView(candidate: candidate)
                        .frame(width: 320)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var heroHeader: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Space you can free")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(ByteFormatter.string(from: store.totalBytes))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    Text("\(store.candidates.count) leftover folders found across your projects")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick guide")
                        .font(.system(.headline, design: .rounded))
                    guideRow(color: CleanupConfidence.safe.tint, title: "Safe to Remove", text: "Usually fine to clear")
                    guideRow(color: CleanupConfidence.likelySafe.tint, title: "Likely Safe", text: "Common leftovers")
                    guideRow(color: CleanupConfidence.review.tint, title: "Review First", text: "Check before removing")
                }
                .padding(20)
                .frame(width: 260, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
            }
        }
    }

    private func guideRow(color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(text)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Picker("Sort", selection: $store.sort) {
                ForEach(ScanSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)

            Spacer()

            Button("Select Visible") {
                store.selectAllFiltered()
            }
            .buttonStyle(.glass)

            Button("Clear Selection") {
                store.deselectAll()
            }
            .buttonStyle(.glass)
            .disabled(store.selectedCandidates.isEmpty)
        }
    }

    private var candidateList: some View {
        List(selection: $store.selectedCandidateID) {
            ForEach(store.filteredCandidates) { candidate in
                CandidateRow(candidate: candidate)
                    .tag(candidate.id)
                    .contextMenu {
                        Button("Reveal in Finder") { store.revealInFinder(candidate) }
                        Button("Copy Path") { store.copyPath(candidate) }
                        Divider()
                        Button("Ignore This Folder") { store.ignoreFolder(candidate) }
                        Button("Ignore Whole Project") { store.ignoreProject(candidate) }
                        Divider()
                        Button("Move to Trash", role: .destructive) {
                            store.deselectAll()
                            store.toggleSelection(candidate.id)
                            store.requestCleanup()
                        }
                    }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

struct CleanEmptyStateView: View {
    @EnvironmentObject private var store: CleanupStore

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(red: 0.18, green: 0.67, blue: 0.45))
                    .padding(24)
                    .glassEffect(.regular.interactive(), in: .circle)

                Text("Looking tidy")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("No removable developer leftovers were found in your selected folders.")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)

                Button {
                    store.startScan()
                } label: {
                    Label("Scan Again", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.glass)
                .padding(.top, 4)
            }
            .padding(36)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 18) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(Color(red: 0.25, green: 0.55, blue: 0.82))
                    .padding(28)
                    .glassEffect(.regular.interactive(), in: .circle)

                Text("Find leftover coding files")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("DevSweep looks through your project folders for things like node_modules and build caches — files your apps can recreate later.")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)

                GlassEffectContainer(spacing: 14) {
                    HStack(spacing: 12) {
                        if preferences.scanRootURLs.isEmpty {
                            Text("Add a project folder on the left, then tap Scan.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                        } else {
                            Button {
                                store.startScan()
                            } label: {
                                Label("Scan My Mac", systemImage: "magnifyingglass")
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .padding(.horizontal, 8)
                            }
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(36)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))

            if store.candidates.isEmpty, store.lastCleanupSummary == nil, !store.isScanning {
                Text("No mysterious “system cleanup”. Only regeneratable developer folders.")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CleanupActionBar: View {
    @EnvironmentObject private var store: CleanupStore

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.selectedCandidates.count) selected")
                    .font(.system(.headline, design: .rounded))
                Text("Ready to move \(ByteFormatter.string(from: store.selectedBytes)) to Trash")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Review & Free Space") {
                store.requestCleanup()
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .glassEffect(.regular.tint(Color(red: 0.25, green: 0.55, blue: 0.82).opacity(0.25)).interactive(), in: .rect(cornerRadius: 22))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
