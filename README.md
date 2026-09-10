# DevSweep

A native macOS utility that scans developer directories for regeneratable build artifacts and dependency folders such as `node_modules`, `.next`, `.turbo`, `DerivedData`, `__pycache__`, etc., shows how much disk space they consume, and lets the user safely delete them from a graphical interface.

The project should be designed as a real, distributable macOS application, not a prototype.

---

# 1. Product Goal

Developers accumulate tens or hundreds of gigabytes of regeneratable files across projects:

```text
node_modules/
.next/
.nuxt/
.turbo/
dist/
build/
coverage/
__pycache__/
.pytest_cache/
.venv/
target/
DerivedData/
```

Finding these manually is annoying.

DevSweep should:

1. Scan selected locations on the Mac.
2. Detect known regeneratable developer directories.
3. Calculate their disk usage.
4. Present them in a clean native macOS UI.
5. Allow filtering, sorting, selecting, and inspecting folders.
6. Move selected folders to Trash safely.
7. Clearly communicate how much storage can be reclaimed.

The app must never blindly delete arbitrary files.

---

# 2. Platform

Target:

```text
Platform: macOS
Language: Swift
UI: SwiftUI
Minimum macOS version: choose a reasonably modern version, ideally macOS 14+
Architecture: Apple Silicon first, but support Intel if practical
```

Prefer native Apple frameworks.

Do NOT use:

```text
Electron
React Native
Tauri
embedded webviews for the main UI
```

unless there is a strong technical reason.

This utility should feel like a native Mac application.

---

# 3. Proposed Name

Working name:

```text
DevSweep
```

Alternatives can be suggested, but do not rename the project unless explicitly instructed.

Bundle identifier can initially be:

```text
dev.harshsinha.devsweep
```

---

# 4. Core User Flow

```text
Launch DevSweep
        ↓
Choose / configure scan locations
        ↓
Scan filesystem
        ↓
Find developer-generated folders
        ↓
Calculate folder sizes
        ↓
Display results
        ↓
Sort / filter / inspect
        ↓
Select folders
        ↓
Review deletion summary
        ↓
Move selected folders to Trash
        ↓
Show reclaimed storage
```

---

# 5. Scan Locations

The application should NOT automatically traverse the entire filesystem by default.

Support configurable scan roots.

Suggested defaults:

```text
~/Developer
~/Projects
~/Documents
~/Desktop
~/Code
~/Workspace
~/Repositories
```

Only include defaults that actually exist.

Users should also be able to add arbitrary directories using `NSOpenPanel`.

Example:

```text
Scan Locations

✓ ~/Developer
✓ ~/Projects
✓ ~/Desktop

+ Add Folder
```

Persist configured roots between launches.

---

# 6. Folder Types

Initial detection rules should include:

## JavaScript / TypeScript

```text
node_modules
.next
.nuxt
.turbo
.parcel-cache
.svelte-kit
coverage
```

## General build output

```text
dist
build
out
.cache
```

Be careful with generic names such as `build`, `dist`, `out`, and `.cache`.

Only classify them when there is reasonable evidence that the parent directory is a software project.

---

## Python

```text
__pycache__
.pytest_cache
.mypy_cache
.ruff_cache
.venv
venv
```

Be more cautious with virtual environments because developers may intentionally want to retain them.

---

## Rust

```text
target
```

Only classify `target` when the surrounding project appears to be a Rust project, for example when `Cargo.toml` exists.

---

## Xcode / Apple

```text
DerivedData
```

Support common Xcode DerivedData locations.

Example:

```text
~/Library/Developer/Xcode/DerivedData
```

---

# 7. Detection Intelligence

Do not simply delete every directory named `build`.

Use project-context detection where practical.

Examples:

```text
node_modules
    → look for package.json nearby

.next
    → look for package.json and/or Next.js dependency

target
    → look for Cargo.toml

__pycache__
    → Python source nearby

DerivedData
    → known Xcode cache location
```

Each result should have a classification.

Example:

```text
Safe to Regenerate
Likely Regeneratable
Review Recommended
```

Suggested model:

```swift
enum CleanupConfidence {
    case safe
    case likelySafe
    case review
}
```

Deletion should remain user-controlled regardless of confidence.

---

# 8. Result Data Model

Each detected directory should roughly contain:

```swift
struct CleanupCandidate {
    let id: UUID

    let url: URL
    let folderName: String
    let projectName: String?

    let sizeBytes: Int64
    let lastModified: Date?

    let category: CleanupCategory
    let confidence: CleanupConfidence

    var isSelected: Bool
}
```

Possible categories:

```text
Dependencies
Build Cache
Build Output
Python Cache
Virtual Environment
Xcode
Test Coverage
Other
```

---

# 9. Main UI

Use a proper desktop layout.

Recommended:

```text
NavigationSplitView
```

Possible structure:

```text
┌────────────────────────────────────────────────────────────┐
│ DevSweep                                    Scan   Settings │
├─────────────────┬──────────────────────────────────────────┤
│                 │                                          │
│ All             │  Reclaimable Storage                    │
│ Dependencies    │                                          │
│ Build Caches    │           27.4 GB                        │
│ Xcode           │                                          │
│ Python          │                                          │
│                 │  [ Search folders... ]                   │
│ Scan Locations  │                                          │
│                 │  ☑ node_modules       8.4 GB             │
│                 │     project-one                           │
│                 │                                          │
│                 │  ☑ .next              3.1 GB             │
│                 │     dashboard                              │
│                 │                                          │
│                 │  ☐ DerivedData         7.8 GB             │
│                 │                                          │
├─────────────────┴──────────────────────────────────────────┤
│ 12 selected                            Move 18.7 GB to Trash │
└────────────────────────────────────────────────────────────┘
```

Do not over-design the sidebar.

Follow native macOS conventions.

---

# 10. Table / List Features

For every result display:

```text
Folder
Project
Path
Category
Size
Last Modified
Confidence
```

Support sorting by:

```text
Size
Name
Last Modified
Project
Category
```

Default sorting:

```text
Size descending
```

Support:

```text
Select all
Deselect all
Search
Filter by category
Filter by confidence
```

---

# 11. Folder Details

Selecting an item should show useful details.

Example:

```text
node_modules

Project
~/Developer/my-app

Size
4.73 GB

Last Modified
3 months ago

Detected because
package.json exists in parent directory

Classification
Safe to Regenerate

[Reveal in Finder]
[Move to Trash]
```

---

# 12. Deletion Behaviour

CRITICAL:

Do NOT use destructive permanent deletion by default.

Use macOS Trash functionality.

Expected UX:

```text
Move 12 folders to Trash?

Storage reclaimed:
18.7 GB

Folders:
• ~/Developer/app/node_modules
• ~/Developer/site/.next
• ...

[Cancel] [Move to Trash]
```

After deletion:

```text
18.7 GB reclaimed
12 folders moved to Trash
```

The user should still be able to restore items from macOS Trash.

---

# 13. Safety Requirements

This is the most important part of the application.

Never delete:

```text
.git
.gitignore
package.json
package-lock.json
pnpm-lock.yaml
yarn.lock
Cargo.toml
Cargo.lock
requirements.txt
pyproject.toml
source files
user documents
project configuration
```

Never recursively delete a project directory.

Only operate on detected cleanup candidate directories.

Before deleting:

1. Resolve the exact filesystem URL.
2. Verify it still exists.
3. Verify it matches the detected cleanup candidate.
4. Verify it is inside an allowed scan root or known safe cache path.
5. Reject dangerous paths.

Explicitly reject paths such as:

```text
/
~
/Users
/Applications
/System
/Library
~/Documents
~/Desktop
```

when they appear as the candidate itself.

A bug in candidate detection must never allow the application to delete the scan root.

---

# 14. Move to Trash

Use the appropriate macOS / Foundation API.

Prefer something conceptually equivalent to:

```swift
FileManager.default.trashItem(...)
```

Do not shell out to:

```bash
rm -rf
```

for normal deletion.

---

# 15. Scanning Performance

Filesystem scanning can be expensive.

The UI must remain responsive.

Requirements:

```text
Perform scanning asynchronously.
Do not block the main thread.
Support cancellation.
Update results progressively if practical.
```

Show progress:

```text
Scanning ~/Developer...

12,481 directories checked
43 cleanup candidates found
17.8 GB detected

[Cancel]
```

Swift concurrency should be preferred:

```swift
async / await
Task
TaskGroup
Actor where useful
```

Avoid creating an uncontrolled number of concurrent filesystem operations.

---

# 16. Folder Size Calculation

Calculate actual folder sizes.

Important concerns:

```text
symbolic links
permission failures
hidden files
package directories containing huge numbers of files
filesystem metadata
```

Do NOT follow symbolic links outside the intended traversal tree.

Handle unreadable directories gracefully.

One inaccessible directory must not fail the entire scan.

---

# 17. Ignore Rules

Users should be able to ignore:

```text
specific projects
specific folders
folder patterns
scan roots
```

Example:

```text
Ignore

~/Developer/important-project

Folder patterns:
.venv
```

Potential future option:

```text
Never suggest deleting dependencies modified within the last X days.
```

---

# 18. Settings

Create a native macOS Settings scene.

Sections can include:

```text
General
Scanning
Cleanup Rules
Ignored Paths
Advanced
```

Possible preferences:

```text
Launch scan automatically
Include hidden directories
Include virtual environments
Include build directories
Minimum folder size
Scan depth
Show review-required folders
```

Persist settings using an appropriate native mechanism such as:

```text
UserDefaults
@AppStorage
```

for simple preferences.

---

# 19. Storage Formatting

Display sizes cleanly.

Examples:

```text
842 MB
4.7 GB
31.2 GB
```

Use Apple's formatting APIs when appropriate.

---

# 20. Context Menu

Right-clicking a result should support:

```text
Reveal in Finder
Copy Path
Ignore Folder
Ignore Project
Move to Trash
```

---

# 21. Keyboard Shortcuts

Useful shortcuts:

```text
⌘R       Scan Again
⌘F       Search
⌘,       Settings
Space    Toggle selection if appropriate
```

Use native macOS command/menu APIs.

---

# 22. Empty States

Examples:

Before scan:

```text
Find developer files taking up space

DevSweep searches for dependencies, build caches,
and regeneratable development files.

[Scan Mac]
```

No results:

```text
Your development folders are clean.

No removable developer artifacts were found.
```

---

# 23. Error Handling

Errors must be human-readable.

Examples:

```text
Could not access ~/Projects/foo

macOS denied permission to this directory.

[Skip]
```

Deletion failure:

```text
3 of 14 folders could not be moved to Trash.

[View Details]
```

Do not crash because one folder cannot be read or deleted.

---

# 24. Permissions

Design filesystem access carefully.

The first version may be used locally and distributed through GitHub outside the Mac App Store.

Do not architect the application around App Store sandboxing unless necessary.

However, keep filesystem-access logic sufficiently isolated that sandbox-compatible access could be added later.

Where the user explicitly selects folders, consider proper macOS security-scoped access patterns if required.

---

# 25. Architecture

Do NOT put everything inside `ContentView.swift`.

Use a structure similar to:

```text
DevSweep/
│
├── App/
│   └── DevSweepApp.swift
│
├── Models/
│   ├── CleanupCandidate.swift
│   ├── CleanupCategory.swift
│   └── CleanupConfidence.swift
│
├── Views/
│   ├── ContentView.swift
│   ├── SidebarView.swift
│   ├── ResultsView.swift
│   ├── CandidateRow.swift
│   ├── CandidateDetailView.swift
│   ├── ScanProgressView.swift
│   └── CleanupConfirmationView.swift
│
├── Services/
│   ├── DirectoryScanner.swift
│   ├── FolderSizeCalculator.swift
│   ├── CleanupService.swift
│   └── ProjectDetector.swift
│
├── Stores/
│   └── CleanupStore.swift
│
├── Support/
│   ├── ByteFormatter.swift
│   └── PathSafetyValidator.swift
│
└── Resources/
```

Keep filesystem logic separate from UI logic.

---

# 26. Suggested Internal Architecture

Conceptually:

```text
SwiftUI
   │
   ↓
CleanupStore
   │
   ├───────────────┐
   ↓               ↓
DirectoryScanner   CleanupService
   │               │
   ↓               ↓
ProjectDetector    Trash API
   │
   ↓
FolderSizeCalculator
```

---

# 27. Scanner Protocol

Design services behind protocols where useful.

Example:

```swift
protocol DirectoryScanning {
    func scan(
        roots: [URL],
        configuration: ScanConfiguration
    ) async throws -> [CleanupCandidate]
}
```

This makes testing significantly easier.

---

# 28. Testing

Add unit tests for important logic.

At minimum:

```text
candidate detection
project detection
path safety validation
folder classification
size formatting
ignore rules
```

Especially test dangerous deletion cases.

Examples:

```text
"/" must be rejected
"/Users/foo" must be rejected
scan root itself must be rejected
project root must be rejected
node_modules inside project should be accepted
```

CleanupService should be testable without actually destroying test fixtures.

Use temporary directories for filesystem tests.

---

# 29. Git Repository

The project should be Git-friendly from the beginning.

Expected:

```text
README.md
LICENSE
.gitignore
DevSweep.xcodeproj
DevSweep/
DevSweepTests/
.github/
```

Recommended license:

```text
MIT
```

unless instructed otherwise.

---

# 30. GitHub Distribution

The project should eventually support releases through GitHub.

Example:

```text
GitHub Releases

DevSweep v0.1.0
├── DevSweep-v0.1.0.zip
└── DevSweep-v0.1.0.dmg
```

Initial releases may be unsigned.

Users downloading an unsigned version may encounter macOS Gatekeeper warnings.

Do NOT require an Apple Developer Program membership for initial development.

---

# 31. Future Signed Distribution

Keep the release pipeline compatible with adding:

```text
Developer ID signing
Hardened Runtime
Apple notarization
stapling
DMG packaging
```

later.

The eventual release flow should be:

```text
Git tag
   ↓
GitHub Actions
   ↓
Build Release
   ↓
Developer ID sign
   ↓
Notarize
   ↓
Create DMG
   ↓
Attach to GitHub Release
```

Signing credentials must never be committed to Git.

---

# 32. Homebrew Support - Future

Potential future distribution:

```bash
brew install --cask devsweep
```

Do not prioritize this for MVP.

---

# 33. MVP

Version `0.1.0` should focus only on:

```text
✓ Native SwiftUI app
✓ Add/remove scan locations
✓ Scan directories
✓ Detect common developer artifacts
✓ Calculate sizes
✓ Sort results
✓ Search results
✓ Multi-select
✓ Reveal in Finder
✓ Move selected folders to Trash
✓ Deletion confirmation
✓ Ignore folder/project
✓ Basic settings
✓ Scan progress
✓ Error handling
✓ Unit tests for safety-critical logic
```

Do not overbuild version 0.1.

---

# 34. Phase 2 Features

Potential additions:

```text
Folder age filters
Project-level grouping
Storage history
Automatic scheduled scanning
Menu bar mode
Duplicate dependency analysis
Package-manager cache cleanup
Docker storage inspection
Simulator cleanup
Android build cache cleanup
Homebrew cache cleanup
Large project discovery
```

---

# 35. Phase 3 Ideas

Possible intelligent functionality:

### Project health

Show:

```text
project-a

node_modules       5.8 GB
.next              2.3 GB
coverage           440 MB

Total reclaimable:
8.54 GB
```

---

### Smart cleanup suggestions

Example:

```text
You have not modified this project in 7 months.

Its node_modules directory consumes 6.2 GB.

Safe to regenerate with:
npm install
```

Do not use an LLM for functionality that can be solved deterministically.

---

### Storage analytics

Potential dashboard:

```text
Developer Storage

Dependencies       42 GB
Build caches       18 GB
Xcode              27 GB
Python              6 GB

Total reclaimable
93 GB
```

---

# 36. Important Engineering Principles

Prioritize, in order:

```text
1. Data safety
2. Correctness
3. Native UX
4. Performance
5. Simplicity
6. Visual polish
```

A storage-cleaning utility losing user data is unacceptable.

When unsure whether something is safe to delete:

```text
classify it as Review Recommended
```

rather than assuming it is safe.

---

# 37. Agent Instructions

When implementing this project:

1. Inspect the existing repository before modifying anything.
2. Do not replace working architecture unnecessarily.
3. Prefer native Swift and SwiftUI APIs.
4. Keep filesystem operations outside UI components.
5. Use Swift concurrency for expensive work.
6. Never introduce `rm -rf` as the main cleanup mechanism.
7. Treat deletion-path validation as security-critical.
8. Add tests whenever safety logic changes.
9. Keep the project compiling after each meaningful milestone.
10. Do not introduce unnecessary external dependencies.
11. Prefer Foundation/AppKit/SwiftUI functionality over third-party libraries.
12. Keep the app compatible with eventual GitHub distribution.
13. Do not require a paid Apple Developer account during development.
14. Document any macOS permission assumptions.
15. Do not silently weaken safety checks to make a feature work.

---

# 38. Implementation Order

Implement in this order:

```text
[ ] 1. Create native macOS SwiftUI project

[ ] 2. Set up proper multi-file architecture

[ ] 3. Create cleanup candidate models

[ ] 4. Implement project/folder detection rules

[ ] 5. Implement filesystem scanner

[ ] 6. Implement folder-size calculation

[ ] 7. Implement path safety validator

[ ] 8. Add scanner unit tests

[ ] 9. Build basic results UI

[ ] 10. Add scan-location management

[ ] 11. Add sorting/filtering/search

[ ] 12. Add selection

[ ] 13. Add Reveal in Finder

[ ] 14. Implement Move to Trash

[ ] 15. Add deletion confirmation dialog

[ ] 16. Add cleanup safety tests

[ ] 17. Add scan progress + cancellation

[ ] 18. Add ignore functionality

[ ] 19. Add Settings

[ ] 20. Improve error handling

[ ] 21. Polish native macOS UX

[ ] 22. Add app icon

[ ] 23. Run complete test suite

[ ] 24. Build Release configuration

[ ] 25. Generate distributable .app/.zip

[ ] 26. Add GitHub Actions CI

[ ] 27. Create GitHub Release workflow

[ ] 28. Document unsigned-install instructions

[ ] 29. Later add Developer ID signing/notarization

[ ] 30. Later add DMG + Homebrew Cask
```

---

# 39. Definition of Done for v0.1

Version 0.1 is complete when a user can:

```text
1. Install/open DevSweep.
2. Choose ~/Developer or another folder.
3. Click Scan.
4. See all discovered developer artifacts.
5. See their individual and combined sizes.
6. Sort them by storage usage.
7. Search/filter them.
8. Select several folders.
9. Review exactly what will be removed.
10. Move them to macOS Trash.
11. See the amount of reclaimed disk space.
```

And importantly:

```text
DevSweep must never delete source code,
project roots, arbitrary user files,
or directories outside the approved candidate set.
```

---

# 40. Product Philosophy

DevSweep should answer one question extremely well:

> "How much disk space are my old development artifacts wasting, and can I safely get that space back?"

The experience should feel closer to a lightweight native developer utility than a generic Mac cleaner.

Fast.

Transparent.

Open source.

No dark patterns.

No mysterious "system cleanup".

No subscriptions.

No unnecessary telemetry.

Just:

```text
Scan → Understand → Select → Trash → Done.
```
