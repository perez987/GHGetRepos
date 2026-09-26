import Combine
import Foundation

#if canImport(AppKit)
import AppKit
#endif

@MainActor
final class AppViewModel: ObservableObject {
    enum RunState {
        case idle
        case running
        case succeeded
        case failed(String)
        case cancelled

        func title(in language: AppLanguage) -> String {
            switch self {
            case .idle:
                return language.text(.runStateReady)
            case .running:
                return language.text(.runStateRunning)
            case .succeeded:
                return language.text(.runStateCompleted)
            case .failed:
                return language.text(.runStateFailed)
            case .cancelled:
                return language.text(.runStateCancelled)
            }
        }
    }

    @Published private(set) var outputLines: [String] = []
    @Published private(set) var runState: RunState = .idle
    @Published private(set) var lastSummary: RepositoryDownloadSummary?

    private var currentTask: Task<Void, Never>?
    private var currentRunID = UUID()

    var isRunning: Bool {
        currentTask != nil
    }

    func run(username: String, token: String?, destinationDirectory: URL?, language: AppLanguage) {
        let runID = UUID()
        let previousTask = currentTask
        currentRunID = runID

        let task = Task.detached { [weak self] in
            guard let self else {
                return
            }

            previousTask?.cancel()
            await previousTask?.value

            guard await self.isCurrentRun(runID) else {
                return
            }

            await self.prepareForRun(runID)

            do {
                let summary = try await RepositoryDownloadRunner(
                    username: username,
                    token: token,
                    destinationDirectory: destinationDirectory,
                    language: language
                ).run { [weak self] line in
                    await self?.appendLine(line, for: runID)
                }

                await self.finishRun(summary: summary, runID: runID)
            } catch {
                await self.finishRun(error: error, language: language, runID: runID)
            }
        }

        currentTask = task
    }

    func cancel() {
        currentTask?.cancel()
    }

    func clearOutput() {
        outputLines.removeAll()
    }

    func copyOutput() {
        let contents = outputLines.joined(separator: "\n")
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(contents, forType: .string)
        #else
        _ = contents
        #endif
    }

    private func appendLine(_ line: String, for runID: UUID? = nil) {
        guard runID == nil || currentRunID == runID else {
            return
        }
        outputLines.append(line)
    }

    private func prepareForRun(_ runID: UUID) {
        guard isCurrentRun(runID) else {
            return
        }
        outputLines = []
        lastSummary = nil
        runState = .running
    }

    private func finishRun(summary: RepositoryDownloadSummary, runID: UUID) {
        guard isCurrentRun(runID) else {
            return
        }
        lastSummary = summary
        runState = .succeeded
        currentTask = nil
    }

    private func finishRun(error: Error, language: AppLanguage, runID: UUID) {
        guard isCurrentRun(runID) else {
            return
        }

        if isCancellationError(error) {
            appendLine("", for: runID)
            appendLine(language.text(.logRunCancelled), for: runID)
            runState = .cancelled
            currentTask = nil
            return
        }

        appendLine("", for: runID)
        let message = language.errorMessage(for: error)
        appendLine(message, for: runID)
        runState = .failed(message)
        currentTask = nil
    }

    private func isCurrentRun(_ runID: UUID) -> Bool {
        currentRunID == runID
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
