# CLAUDE.md

## Project overview

- `GHGetRepos` is a native macOS 14+ SwiftUI app with two tools: downloading repositories and reporting total release-asset downloads for a GitHub account.
- The Xcode project is under `Xcode-project/`.
- App source lives in `Xcode-project/GHGetRepos/`.
- UI code lives in `Xcode-project/GHGetRepos/Views/`.
- State, networking, and run logic live in `Xcode-project/GHGetRepos/Model/`.

## Important files

- `Xcode-project/GHGetRepos/GHGetReposApp.swift`: app entry point and shared `SettingsStore` injection.
- `Xcode-project/GHGetRepos/Views/ContentView.swift`: main two-tab window (`Get Repos` + `Total Downloads`).
- `Xcode-project/GHGetRepos/Views/SettingsView.swift`: username, token, and language settings UI.
- `Xcode-project/GHGetRepos/Views/OutputLogView.swift`: selectable live log output with auto-scroll behavior.
- `Xcode-project/GHGetRepos/Model/AppViewModel.swift`: shared run lifecycle, cancellation handling, and per-tool view models.
- `Xcode-project/GHGetRepos/Model/RepositoryDownloadRunner.swift`: repository listing, tarball download/extraction flow, total-downloads report flow, and result summaries.
- `Xcode-project/GHGetRepos/Model/GitHubAPI.swift`: GitHub API models, requests, and HTTP helpers.
- `Xcode-project/GHGetRepos/Model/SettingsStore.swift`: persisted username/language/destination plus token-loading bridge.
- `Xcode-project/GHGetRepos/Model/KeychainTokenStore.swift`: Keychain-backed token storage (`github-repo-downloads` service).

## Working conventions

- Prefer small, focused SwiftUI and model changes.
- Keep token handling in the Keychain-backed store; do not move secrets into `UserDefaults`.
- Preserve cancellation behavior for long-running operations (repository archive downloads/extraction and downloads reporting).
- The app runs in the App Sandbox: do not launch `/usr/bin/git` (an `xcrun` shim that fails in the sandbox). Repositories are fetched as default-branch tarballs via the GitHub API and extracted with `/usr/bin/tar` in a temporary workspace inside the container, then moved into the destination.
- Destination folder access is persisted as a security-scoped bookmark (`SettingsStore.securityScopedDestinationURL()`); wrap destination access in `start/stopAccessingSecurityScopedResource()`.
- Preserve current destination behavior: repository folders are named by repository name, existing folders are overwritten, and existing non-folder items fail.

## Validation

- Open in Xcode: `Xcode-project/GHGetRepos.xcodeproj`
- Validate from repository root:
  - `xcodebuild -project Xcode-project/GHGetRepos.xcodeproj -scheme GHGetRepos -destination 'platform=macOS' build`
- There is currently no test target checked into this repository.

## Notes for agents

- This is a SwiftUI desktop app, not a package or command-line tool.
- The main app window uses a two-tab `TabView` for repository downloads and total-downloads reporting.
- Avoid broad UI restyling unless the task specifically asks for it.
