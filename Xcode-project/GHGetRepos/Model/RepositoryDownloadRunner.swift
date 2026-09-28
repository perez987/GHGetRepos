import Foundation

final class SingleResumeGate: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    func run(_ action: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard didResume == false else {
            return
        }
        didResume = true
        action()
    }

    func reset() {
        lock.lock()
        didResume = false
        lock.unlock()
    }
}

final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    func markCancelled() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }
}

final class ProcessContinuationCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?
    private let gate = SingleResumeGate()

    func store(_ continuation: CheckedContinuation<Void, Error>) {
        lock.lock()
        defer { lock.unlock() }
        gate.reset()
        self.continuation = continuation
    }

    func resume(_ result: Result<Void, Error>) {
        lock.lock()
        let continuation = self.continuation
        lock.unlock()

        guard let continuation else {
            return
        }

        gate.run {
            self.lock.lock()
            self.continuation = nil
            self.lock.unlock()

            switch result {
            case .success:
                continuation.resume()
            case let .failure(error):
                continuation.resume(throwing: error)
            }
        }
    }
}

struct RepositoryDownloadSummary {
    let repositoryCount: Int
    let downloadedCount: Int
    let skippedCount: Int
    let failedCount: Int
}

struct DownloadsReportSummary {
    let repositoryCount: Int
    let repositoriesWithDownloads: Int
    let totalDownloads: Int
}

struct DownloadsTableFormatter {
    private static let minimumNameWidth = 45
    private static let minimumCountWidth = 15

    let language: AppLanguage

    private var nameWidth: Int {
        max(Self.minimumNameWidth, language.text(.downloadsTableRepositoryHeader).count)
    }

    private var countWidth: Int {
        max(Self.minimumCountWidth, language.text(.downloadsTableDownloadsHeader).count)
    }

    func header() -> [String] {
        [
            row(name: language.text(.downloadsTableRepositoryHeader), count: language.text(.downloadsTableDownloadsHeader)),
            row(name: String(repeating: "-", count: nameWidth), count: String(repeating: "-", count: countWidth)),
        ]
    }

    func repositoryRow(name: String, downloads: Int) -> String {
        row(name: name, count: String(downloads))
    }

    func footer(totalDownloads: Int) -> [String] {
        [
            row(name: String(repeating: "-", count: nameWidth), count: String(repeating: "-", count: countWidth)),
            row(name: language.text(.totalDownloads).uppercased(with: language.locale), count: String(totalDownloads)),
        ]
    }

    private func row(name: String, count: String) -> String {
        let left = truncate(name, to: nameWidth).padding(toLength: nameWidth, withPad: " ", startingAt: 0)
        let right = count.leftPadded(to: countWidth)
        return "\(left) \(right)"
    }

    private func truncate(_ value: String, to width: Int) -> String {
        guard value.count > width else {
            return value
        }

        let suffix = "…"
        let prefixCount = max(width - suffix.count, 0)
        return String(value.prefix(prefixCount)) + suffix
    }
}

struct DownloadsReportRunner {
    private static let maxConcurrentRepositoryRequests = 6

    let username: String
    let token: String?
    let language: AppLanguage

    func run(emit: @escaping @Sendable (String) async -> Void) async throws -> DownloadsReportSummary {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUsername.isEmpty == false else {
            throw GitHubAPIError.invalidUsername
        }

        let client = GitHubAPIClient(username: trimmedUsername, token: token)
        let formatter = DownloadsTableFormatter(language: language)
        let fetchRepositories = try await repositoryPageFetcher(client: client, username: trimmedUsername)

        await emit(language.formatted(.logUser, trimmedUsername))
        await emit(language.text(.logQueryingReleaseDownloads))
        await emit("")
        for line in formatter.header() {
            await emit(line)
        }

        var allRepositories: [GitHubRepository] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let repositories = try await fetchRepositories(page)
            guard repositories.isEmpty == false else {
                break
            }

            allRepositories.append(contentsOf: repositories)
            if repositories.count < 100 {
                break
            }
            page += 1
        }

        if allRepositories.isEmpty {
            await emit(language.text(.logNoRepositoriesFound))
        } else {
            let downloadsByRepository = try await fetchDownloadsByRepository(
                repositories: allRepositories,
                username: trimmedUsername,
                token: token
            )

            var grandTotal = 0
            var repositoriesWithDownloads = 0

            for (repository, downloads) in zip(allRepositories, downloadsByRepository) {
                await emit(formatter.repositoryRow(name: repository.name, downloads: downloads))
                grandTotal += downloads
                if downloads > 0 {
                    repositoriesWithDownloads += 1
                }
            }

            for line in formatter.footer(totalDownloads: grandTotal) {
                await emit(line)
            }
            await emit("")
            await emit(language.formatted(.logRepositoriesAnalyzed, allRepositories.count))
            await emit(language.formatted(.logRepositoriesWithDownloads, repositoriesWithDownloads))

            return DownloadsReportSummary(
                repositoryCount: allRepositories.count,
                repositoriesWithDownloads: repositoriesWithDownloads,
                totalDownloads: grandTotal
            )
        }

        for line in formatter.footer(totalDownloads: 0) {
            await emit(line)
        }
        await emit("")
        await emit(language.formatted(.logRepositoriesAnalyzed, 0))
        await emit(language.formatted(.logRepositoriesWithDownloads, 0))
        return DownloadsReportSummary(
            repositoryCount: 0,
            repositoriesWithDownloads: 0,
            totalDownloads: 0
        )
    }

    private func repositoryPageFetcher(
        client: GitHubAPIClient,
        username: String
    ) async throws -> (Int) async throws -> [GitHubRepository] {
        if token?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
           let authenticatedUser = try? await client.fetchAuthenticatedUser(),
           authenticatedUser.login.caseInsensitiveCompare(username) == .orderedSame
        {
            return { page in
                try await client.fetchAuthenticatedRepositories(page: page)
            }
        }

        let account = try await client.fetchRequestedAccount()
        switch account.type {
        case .user:
            return { page in
                try await client.fetchPublicUserRepositories(page: page)
            }
        case .organization:
            return { page in
                try await client.fetchOrganizationRepositories(page: page)
            }
        }
    }

    private func fetchDownloadsByRepository(
        repositories: [GitHubRepository],
        username: String,
        token: String?
    ) async throws -> [Int] {
        let initialCount = min(Self.maxConcurrentRepositoryRequests, repositories.count)
        var nextIndex = initialCount
        var downloadsByRepository = Array(repeating: 0, count: repositories.count)

        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            for index in 0 ..< initialCount {
                addDownloadsTask(
                    to: &group,
                    index: index,
                    repository: repositories[index],
                    username: username,
                    token: token
                )
            }

            while let (index, downloads) = try await group.next() {
                downloadsByRepository[index] = downloads
                if nextIndex < repositories.count {
                    addDownloadsTask(
                        to: &group,
                        index: nextIndex,
                        repository: repositories[nextIndex],
                        username: username,
                        token: token
                    )
                    nextIndex += 1
                }
            }
        }

        return downloadsByRepository
    }

    private func addDownloadsTask(
        to group: inout ThrowingTaskGroup<(Int, Int), Error>,
        index: Int,
        repository: GitHubRepository,
        username: String,
        token: String?
    ) {
        group.addTask {
            let client = GitHubAPIClient(username: username, token: token)
            let downloads = try await Self.fetchDownloads(for: repository, client: client)
            return (index, downloads)
        }
    }

    private static func fetchDownloads(for repository: GitHubRepository, client: GitHubAPIClient) async throws -> Int {
        var page = 1
        var total = 0

        while true {
            try Task.checkCancellation()
            let releases = try await client.fetchReleases(
                ownerName: repository.owner.login,
                repositoryName: repository.name,
                page: page
            )
            guard releases.isEmpty == false else {
                break
            }

            total += releases
                .flatMap(\.assets)
                .reduce(0) { partialResult, asset in
                    partialResult + asset.downloadCount
                }

            if releases.count < 100 {
                break
            }
            page += 1
        }

        return total
    }
}

private let maxUTF8BoundaryTrimBytes = 4

private struct GitAskPassFiles {
    let directoryURL: URL
    let scriptURL: URL
    let outputFileURL: URL
}

struct RepositoryDownloadRunner {
    let username: String
    let token: String?
    let destinationDirectory: URL?
    let language: AppLanguage

    func run(emit: @escaping @Sendable (String) async -> Void) async throws -> RepositoryDownloadSummary {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUsername.isEmpty == false else {
            throw GitHubAPIError.invalidUsername
        }

        let trimmedToken = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard trimmedToken.isEmpty == false else {
            throw GitHubAPIError.missingToken
        }

        guard let destinationDirectory, isExistingDirectory(destinationDirectory) else {
            throw GitHubAPIError.invalidDestination
        }

        let client = GitHubAPIClient(username: trimmedUsername, token: trimmedToken)
        let authenticatedUser = try await client.fetchAuthenticatedUser()
        guard authenticatedUser.login.caseInsensitiveCompare(trimmedUsername) == .orderedSame else {
            throw GitHubAPIError.usernameTokenMismatch(expected: trimmedUsername, actual: authenticatedUser.login)
        }

        for line in startupLogLines(username: trimmedUsername, destinationPath: destinationDirectory.path) {
            await emit(line)
        }

        var allRepositories: [GitHubRepository] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let repositories = try await client.fetchAuthenticatedRepositories(page: page)
            guard repositories.isEmpty == false else {
                break
            }

            let ownedRepositories = ownedRepositories(in: repositories, for: trimmedUsername)
            allRepositories.append(contentsOf: ownedRepositories)
            if repositories.count < 100 {
                break
            }
            page += 1
        }

        if allRepositories.isEmpty {
            await emit(language.text(.logNoRepositoriesFound))
            return RepositoryDownloadSummary(repositoryCount: 0, downloadedCount: 0, skippedCount: 0, failedCount: 0)
        }

        var downloadedCount = 0
        var skippedCount = 0
        var failedCount = 0

        for repository in allRepositories {
            try Task.checkCancellation()
            do {
                await emit(downloadingLogLine(for: repository.name))
                try await download(
                    repository: repository,
                    destinationDirectory: destinationDirectory,
                    username: trimmedUsername,
                    token: trimmedToken
                )
                downloadedCount += 1
                await emit(downloadedLogLine(for: repository.name))
            } catch let error as GitHubAPIError {
                switch error {
                case .existingDestinationFolder:
                    skippedCount += 1
                    await emit(skippedLogLine(for: repository.name))
                default:
                    failedCount += 1
                    await emit(failedLogLine(for: repository.name, error: error))
                }
            } catch {
                if isCancellationError(error) {
                    throw error
                }
                failedCount += 1
                await emit(failedLogLine(for: repository.name, error: error))
            }
        }

        for line in summaryLogLines(
            repositoryCount: allRepositories.count,
            downloadedCount: downloadedCount,
            skippedCount: skippedCount,
            failedCount: failedCount
        ) {
            await emit(line)
        }

        return RepositoryDownloadSummary(
            repositoryCount: allRepositories.count,
            downloadedCount: downloadedCount,
            skippedCount: skippedCount,
            failedCount: failedCount
        )
    }

    private func download(repository: GitHubRepository, destinationDirectory: URL, username: String, token: String) async throws {
        let repositoryFolderURL = destinationDirectory.appendingPathComponent(destinationFolderName(for: repository), isDirectory: true)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: repositoryFolderURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                throw GitHubAPIError.existingDestinationFolder(repository.name)
            }
            throw GitHubAPIError.existingDestinationItem(repository.name)
        }

        do {
            try await cloneRepository(repository, to: repositoryFolderURL, username: username, token: token)
        } catch {
            if FileManager.default.fileExists(atPath: repositoryFolderURL.path) {
                try? FileManager.default.removeItem(at: repositoryFolderURL)
            }
            throw error
        }
    }

    private func cloneRepository(_ repository: GitHubRepository, to destinationURL: URL, username: String, token: String) async throws {
        let cloneURL = try validatedCloneURL(for: repository)
        let askPassFiles = try makeGitAskPassFiles(token: token)
        defer {
            try? FileManager.default.removeItem(at: askPassFiles.directoryURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = destinationURL.deletingLastPathComponent()
        process.arguments = cloneArguments(for: repository, cloneURL: cloneURL, destinationName: destinationURL.lastPathComponent)
        process.environment = gitEnvironment(
            username: username,
            scriptURL: askPassFiles.scriptURL,
            homeDirectory: askPassFiles.directoryURL
        )
        let outputHandle = try FileHandle(forWritingTo: askPassFiles.outputFileURL)
        defer {
            try? outputHandle.close()
        }
        process.standardError = outputHandle
        process.standardOutput = outputHandle
        let coordinator = ProcessContinuationCoordinator()
        let cancellationFlag = CancellationFlag()

        try Task.checkCancellation()

        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                coordinator.store(continuation)

                if Task.isCancelled {
                    coordinator.resume(.failure(CancellationError()))
                    return
                }

                process.terminationHandler = { completedProcess in
                    if completedProcess.terminationStatus == 0 {
                        coordinator.resume(.success(()))
                    } else if cancellationFlag.isCancelled {
                        coordinator.resume(.failure(CancellationError()))
                    } else {
                        try? outputHandle.synchronize()
                        try? outputHandle.close()
                        let details = processErrorMessage(from: askPassFiles.outputFileURL, maxByteCount: 8192)
                        coordinator.resume(.failure(GitHubAPIError.gitCloneFailed(details)))
                    }
                }

                do {
                    try process.run()
                } catch {
                    coordinator.resume(.failure(GitHubAPIError.gitCloneFailed(error.localizedDescription)))
                }
            }
        }, onCancel: {
            cancellationFlag.markCancelled()
            if process.isRunning {
                process.terminate()
            }
        })
    }

    func cloneArguments(for repository: GitHubRepository, cloneURL: String, destinationName: String) -> [String] {
        var arguments = [
            "-c", "credential.helper=",
            "-c", "http.version=HTTP/1.1",
            "clone",
            "--depth", "1",
            "--single-branch",
        ]
        if repository.defaultBranch.isEmpty == false {
            arguments.append(contentsOf: ["--branch", repository.defaultBranch])
        }
        arguments.append(contentsOf: [cloneURL, destinationName])
        return arguments
    }

    func destinationFolderName(for repository: GitHubRepository) -> String {
        "\(repository.name)"
    }

    func ownedRepositories(in repositories: [GitHubRepository], for username: String) -> [GitHubRepository] {
        repositories.filter {
            $0.owner.login.caseInsensitiveCompare(username) == .orderedSame
        }
    }

    func startupLogLines(username: String, destinationPath: String) -> [String] {
        [
            language.formatted(.logUser, username),
            language.formatted(.logDestination, destinationPath),
            language.text(.logQueryingRepositories),
            "",
        ]
    }

    func downloadedLogLine(for repositoryName: String) -> String {
        language.formatted(.logDownloadedRepository, repositoryName)
    }

    func downloadingLogLine(for repositoryName: String) -> String {
        language.formatted(.logDownloadingRepository, repositoryName)
    }

    func skippedLogLine(for repositoryName: String) -> String {
        language.formatted(.logSkippedRepository, repositoryName)
    }

    func failedLogLine(for repositoryName: String, error: Error) -> String {
        language.formatted(.logFailedRepository, repositoryName, language.errorMessage(for: error))
    }

    func summaryLogLines(repositoryCount: Int, downloadedCount: Int, skippedCount: Int, failedCount: Int) -> [String] {
        [
            "",
            language.formatted(.logRepositoriesFound, repositoryCount),
            language.formatted(.logDownloadedCount, downloadedCount),
            language.formatted(.logSkippedCount, skippedCount),
            language.formatted(.logFailedCount, failedCount),
        ]
    }

    private func makeGitAskPassFiles(token: String) throws -> GitAskPassFiles {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )

            let tokenFileURL = directoryURL.appendingPathComponent("git-token")
            let createdTokenFile = FileManager.default.createFile(
                atPath: tokenFileURL.path,
                contents: Data(token.utf8),
                attributes: [.posixPermissions: 0o600]
            )
            guard createdTokenFile else {
                throw GitHubAPIError.gitCloneFailed(nil)
            }

            let outputFileURL = directoryURL.appendingPathComponent("git-output")
            let createdOutputFile = FileManager.default.createFile(
                atPath: outputFileURL.path,
                contents: Data(),
                attributes: [.posixPermissions: 0o600]
            )
            guard createdOutputFile else {
                throw GitHubAPIError.gitCloneFailed(nil)
            }

            let scriptURL = directoryURL.appendingPathComponent("git-askpass.sh")
            let script = """
            #!/bin/sh
            script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
            prompt=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
            case "$prompt" in
              *username*|*"user name"*)
                printf '%s\n' "$GHGETREPOS_GIT_USERNAME"
                ;;
              *password*|*token*)
                tr -d '\n' < "$script_dir/git-token"
                printf '\n'
                ;;
              *)
                printf '\n'
                ;;
            esac
            """
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)
            return GitAskPassFiles(
                directoryURL: directoryURL,
                scriptURL: scriptURL,
                outputFileURL: outputFileURL
            )
        } catch {
            try? FileManager.default.removeItem(at: directoryURL)
            throw error
        }
    }

    private func gitEnvironment(username: String, scriptURL: URL, homeDirectory: URL) -> [String: String] {
        let inheritedEnvironment = ProcessInfo.processInfo.environment
        var environment: [String: String] = [:]
        for key in [
            "PATH",
            "TMPDIR",
            "LANG",
            "LC_ALL",
            "USER",
            "LOGNAME",
            "SSL_CERT_FILE",
            "SSL_CERT_DIR",
            "CURL_CA_BUNDLE",
            "http_proxy",
            "https_proxy",
            "HTTP_PROXY",
            "HTTPS_PROXY",
            "no_proxy",
            "NO_PROXY",
            "ALL_PROXY",
        ] {
            if let value = inheritedEnvironment[key] {
                environment[key] = value
            }
        }
        environment["HOME"] = homeDirectory.path
        environment["GIT_CONFIG_NOSYSTEM"] = "1"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["GIT_ASKPASS"] = scriptURL.path
        environment["GHGETREPOS_GIT_USERNAME"] = username
        return environment
    }

    func validatedCloneURL(for repository: GitHubRepository) throws -> String {
        let actualComponents = try normalizedCloneURLComponents(for: repository.cloneURL)
        let expectedComponents = try expectedCloneURLComponents(for: repository)
        guard actualComponents.scheme?.caseInsensitiveCompare(expectedComponents.scheme ?? "") == .orderedSame,
              actualComponents.host?.caseInsensitiveCompare(expectedComponents.host ?? "") == .orderedSame
        else {
            throw GitHubAPIError.invalidResponse
        }
        guard normalizedHTTPSPort(for: actualComponents) == normalizedHTTPSPort(for: expectedComponents) else {
            throw GitHubAPIError.invalidResponse
        }
        guard decodedPathComponents(from: actualComponents).elementsEqual(
            decodedPathComponents(from: expectedComponents),
            by: { $0.caseInsensitiveCompare($1) == .orderedSame }
        ) else {
            throw GitHubAPIError.invalidResponse
        }
        guard let normalizedURL = expectedComponents.url else {
            throw GitHubAPIError.invalidResponse
        }
        return normalizedURL.absoluteString
    }

    private func normalizedCloneURLComponents(for cloneURL: String) throws -> URLComponents {
        guard let components = URLComponents(string: cloneURL),
              components.scheme?.caseInsensitiveCompare("https") == .orderedSame,
              components.query == nil,
              components.fragment == nil,
              components.user == nil,
              components.percentEncodedUser == nil,
              components.password == nil,
              components.percentEncodedPassword == nil,
              components.percentEncodedPath.contains(";") == false,
              components.url != nil
        else {
            throw GitHubAPIError.invalidResponse
        }
        return components
    }

    private func expectedCloneURLComponents(for repository: GitHubRepository) throws -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = GitHubAPIClient.repositoryHost
        components.port = GitHubAPIClient.repositoryPort
        components.percentEncodedPath = "/" + percentEncodedPathComponent(repository.owner.login) + "/" + percentEncodedPathComponent(repository.name) + ".git"
        guard components.url != nil else {
            throw GitHubAPIError.invalidResponse
        }
        return components
    }

    private func normalizedHTTPSPort(for components: URLComponents) -> Int {
        components.port ?? 443
    }

    private func decodedPathComponents(from components: URLComponents) -> [String] {
        (components.url?.pathComponents ?? [])
            .filter { $0 != "/" }
            .map { $0.removingPercentEncoding ?? $0 }
    }

    private func percentEncodedPathComponent(_ component: String) -> String {
        let allowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        return component.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? component
    }

    func processErrorMessage(from fileURL: URL, maxByteCount: Int) -> String? {
        guard let data = processOutputTailData(from: fileURL, maxByteCount: maxByteCount) else {
            return nil
        }
        return decodeProcessOutputTail(data)
    }

    private func processOutputTailData(from fileURL: URL, maxByteCount: Int) -> Data? {
        guard maxByteCount > 0 else {
            return nil
        }
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            return nil
        }
        defer {
            try? handle.close()
        }
        let fileSize = (try? handle.seekToEnd()) ?? 0
        let startingOffset = fileSize > UInt64(maxByteCount) ? fileSize - UInt64(maxByteCount) : 0
        guard (try? handle.seek(toOffset: startingOffset)) != nil,
              let data = try? handle.readToEnd()
        else {
            return nil
        }
        return data.count > maxByteCount ? Data(data.suffix(maxByteCount)) : data
    }

    private func decodeProcessOutputTail(_ data: Data) -> String? {
        guard data.isEmpty == false else {
            return nil
        }
        let trimLimit = min(maxUTF8BoundaryTrimBytes, data.count)
        for prefixOffset in 0 ... trimLimit {
            let prefixTrimmed = Data(data.dropFirst(prefixOffset))
            for suffixOffset in 0 ... min(maxUTF8BoundaryTrimBytes, prefixTrimmed.count) {
                let candidate = suffixOffset == 0 ? prefixTrimmed : Data(prefixTrimmed.dropLast(suffixOffset))
                if let string = String(data: candidate, encoding: .utf8) {
                    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }
            }
        }
        return nil
    }

    private func isExistingDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == URLError.cancelled.rawValue
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        guard count < width else {
            return self
        }
        return String(repeating: " ", count: width - count) + self
    }
}
