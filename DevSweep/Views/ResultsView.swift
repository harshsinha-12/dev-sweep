import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var store: CleanupStore

    var body: some View {
        Group {
            if store.isScanning {
                ScanProgressView()
            } else if store.candidates.isEmpty {
                store.hasCompletedScan ? AnyView(CleanEmptyStateView()) : AnyView(EmptyStateView())
            } else {
                resultsContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !store.selectedCandidates.isEmpty {
                CleanupActionBar()
            }
        }
    }

    private var resultsContent: some View {
        GeometryReader { proxy in
            VStack(spacing: 14) {
                summaryHeader

                if let summary = store.lastCleanupSummary {
                    successBanner(summary)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                controls

                HStack(alignment: .top, spacing: 14) {
                    candidateList

                    if proxy.size.width >= 760, let candidate = store.selectedCandidate {
                        CandidateDetailView(candidate: candidate)
                            .frame(width: min(310, proxy.size.width * 0.34))
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, DS.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .animation(.snappy(duration: 0.24), value: store.selectedCandidateID)
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 7)
                Circle()
                    .trim(from: 0.06, to: 0.82)
                    .stroke(
                        AngularGradient(
                            colors: [DS.accent, DS.cyan, DS.mint, DS.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(DS.accent)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                SectionEyebrow(text: "Reclaimable Space")
                Text(ByteFormatter.string(from: store.totalBytes))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("\(store.candidates.count) regeneratable folders found")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            HStack(spacing: 0) {
                summaryMetric(
                    value: safeCandidateCount.formatted(),
                    label: "Safe",
                    color: DS.mint
                )
                Divider()
                    .frame(height: 34)
                    .padding(.horizontal, 18)
                summaryMetric(
                    value: reviewCandidateCount.formatted(),
                    label: "Review",
                    color: DS.amber
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .panelBackground()
    }

    private var safeCandidateCount: Int {
        store.candidates.filter { $0.confidence == .safe }.count
    }

    private var reviewCandidateCount: Int {
        store.candidates.filter { $0.confidence != .safe }.count
    }

    private func summaryMetric(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
            }
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func successBanner(_ summary: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DS.mint)
            Text(summary)
                .font(.system(.callout, design: .rounded, weight: .medium))
            Spacer()
            Button {
                store.startScan()
            } label: {
                Label("Scan Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(DS.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DS.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(DS.mint.opacity(0.24))
        )
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Sort", selection: $store.sort) {
                    ForEach(ScanSort.allCases) { sort in
                        Text(sort.title).tag(sort)
                    }
                }
            } label: {
                Label(store.sort.title, systemImage: "arrow.up.arrow.down")
            }
            .menuStyle(.button)
            .buttonStyle(.glass)

            if store.selectedCategory != nil || store.selectedConfidence != nil || !store.searchText.isEmpty {
                Button {
                    withAnimation(.snappy) {
                        store.selectedCategory = nil
                        store.selectedConfidence = nil
                        store.searchText = ""
                    }
                } label: {
                    Label("Clear Filters", systemImage: "line.3.horizontal.decrease.circle.fill")
                }
                .buttonStyle(.glass)
            }

            Spacer()

            Text("\(store.filteredCandidates.count) shown")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)

            Button {
                store.selectAllFiltered()
            } label: {
                Label("Select All", systemImage: "checkmark.circle")
            }
            .buttonStyle(.glass)

            if !store.selectedCandidates.isEmpty {
                Button {
                    store.deselectAll()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .buttonStyle(.glass)
            }
        }
        .controlSize(.small)
    }

    private var candidateList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Size")
                    .frame(width: 92, alignment: .trailing)
            }
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)

            Divider().opacity(0.4)

            if store.filteredCandidates.isEmpty {
                ContentUnavailableView(
                    "No Matching Results",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try clearing your search or filters.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 7) {
                        ForEach(store.filteredCandidates) { candidate in
                            CandidateRow(candidate: candidate)
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
                    .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .panelBackground()
        .clipShape(RoundedRectangle(cornerRadius: DS.contentCornerRadius, style: .continuous))
    }
}

struct CleanEmptyStateView: View {
    @EnvironmentObject private var store: CleanupStore

    var body: some View {
        CenteredStateCard(
            icon: "checkmark.circle.fill",
            tint: DS.mint,
            eyebrow: "Scan Complete",
            title: "Everything looks tidy",
            message: "No removable developer leftovers were found in your selected folders."
        ) {
            Button {
                store.startScan()
            } label: {
                Label("Scan Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.glassProminent)
            .tint(DS.accent)
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var store: CleanupStore
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        CenteredStateCard(
            icon: "sparkles.rectangle.stack.fill",
            tint: DS.accent,
            eyebrow: "Welcome to DevSweep",
            title: "Make room for what matters",
            message: "Find dependency folders, build caches, and other developer files that your projects can safely recreate."
        ) {
            if preferences.scanRootURLs.isEmpty {
                Label("Add a scan folder from the sidebar", systemImage: "arrow.left")
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    store.startScan()
                } label: {
                    Label("Start First Scan", systemImage: "sparkle.magnifyingglass")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(DS.accent)
                .controlSize(.large)
            }
        }
    }
}

private struct CenteredStateCard<Actions: View>: View {
    let icon: String
    let tint: Color
    let eyebrow: String
    let title: String
    let message: String
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack {
            Spacer(minLength: 30)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                    Circle()
                        .strokeBorder(tint.opacity(0.24))
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 76, height: 76)
                .glassEffect(.regular.interactive(), in: .circle)

                VStack(spacing: 8) {
                    SectionEyebrow(text: eyebrow)
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(message)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 520)
                }

                actions
                    .padding(.top, 4)

                HStack(spacing: 7) {
                    Image(systemName: "trash.slash")
                    Text("Nothing is permanently deleted")
                }
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
            }
            .padding(.horizontal, 54)
            .padding(.vertical, 42)
            .glassEffect(.regular, in: .rect(cornerRadius: 30))

            Spacer(minLength: 30)
        }
        .padding(DS.pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CleanupActionBar: View {
    @EnvironmentObject private var store: CleanupStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DS.accent.opacity(0.15))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.accent)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(store.selectedCandidates.count) selected")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                Text("\(ByteFormatter.string(from: store.selectedBytes)) ready to reclaim")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Clear") {
                withAnimation(.snappy) {
                    store.deselectAll()
                }
            }
            .buttonStyle(.glass)

            Button {
                store.requestCleanup()
            } label: {
                Label("Review Cleanup", systemImage: "trash")
            }
            .buttonStyle(.glassProminent)
            .tint(DS.accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(
            .regular.tint(DS.accent.opacity(0.11)).interactive(),
            in: .rect(cornerRadius: 18)
        )
        .padding(.horizontal, DS.pagePadding)
        .padding(.bottom, 14)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
