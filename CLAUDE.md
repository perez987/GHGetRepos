# CLAUDE.md

## Project overview
- `GHGetRepos` is a native macOS 14+ SwiftUI app that downloads repositories owned by a GitHub account into a user-selected folder.
- The UI lives in `GHGetRepos/Views/`.
- App state and download logic live in `GHGetRepos/Model/`.
- Tests live in `GHGetReposTests/`.

## Important files
- `GHGetRepos/GHGetReposApp.swift`: app entry point.
- `GHGetRepos/Views/ContentView.swift`: main window and download controls.
- `GHGetRepos/Views/SettingsView.swift`: username, token, and destination settings UI.
- `GHGetRepos/Model/AppViewModel.swift`: run lifecycle, output log state, and cancellation handling.
- `GHGetRepos/Model/RepositoryDownloadRunner.swift`: repository listing, archive download, extraction, and result summary logic.
- `GHGetRepos/Model/GitHubAPI.swift`: GitHub API models, requests, and download helpers.
- `GHGetRepos/Model/SettingsStore.swift`: persisted settings and destination selection.
- `GHGetRepos/Model/KeychainTokenStore.swift`: Keychain-backed token storage.

## Working conventions
- Prefer small, focused SwiftUI and model changes.
- Keep token handling in the Keychain-backed store; do not move secrets into `UserDefaults`.
- Preserve cancellation behavior for downloads and archive extraction.
- Preserve repository extraction safety checks, especially the rejection of invalid layouts and symlinks.
- Preserve repository folder naming behavior that includes the repository ID.

## Validation
- Open in Xcode: `GHGetRepos.xcodeproj`
- Run tests from the repository root:
  - `xcodebuild -project GHGetRepos.xcodeproj -scheme GHGetRepos -destination 'platform=macOS' test`

## Notes for agents
- This is a SwiftUI desktop app, not a package or command-line tool.
- Most behavioral changes should include or update focused tests in `GHGetReposTests/` when practical.
- Avoid broad UI restyling unless the task specifically asks for it.
