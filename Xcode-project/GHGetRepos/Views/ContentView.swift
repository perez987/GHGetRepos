import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.26),
                    Color(red: 0.14, green: 0.24, blue: 0.34),
                    Color(red: 0.20, green: 0.18, blue: 0.32),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                heroCard
                metricsRow
                controlsRow
                outputCard
            }
            .padding(24)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(settings.text(.appTitle), systemImage: "square.and.arrow.down.fill")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(settings.text(.appSubtitle))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                stateBadge
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    detailChip(title: settings.text(.githubUser), value: settings.trimmedUsername().isEmpty ? settings.text(.notSet) : settings.trimmedUsername())
                    detailChip(title: settings.text(.tokenLabel), value: settings.hasStoredToken ? settings.text(.tokenStored) : settings.text(.tokenRequired))
                    detailChip(title: settings.text(.destinationLabel), value: settings.trimmedDestinationPath().isEmpty ? settings.text(.chooseAFolder) : settings.trimmedDestinationPath())
                }

                VStack(spacing: 12) {
                    detailChip(title: settings.text(.githubUser), value: settings.trimmedUsername().isEmpty ? settings.text(.notSet) : settings.trimmedUsername())
                    detailChip(title: settings.text(.tokenLabel), value: settings.hasStoredToken ? settings.text(.tokenStored) : settings.text(.tokenRequired))
                    detailChip(title: settings.text(.destinationLabel), value: settings.trimmedDestinationPath().isEmpty ? settings.text(.chooseAFolder) : settings.trimmedDestinationPath())
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var metricsRow: some View {
        HStack(spacing: 16) {
            summaryCard(title: settings.text(.repositories), value: summaryValue { String($0.repositoryCount) }, symbol: "shippingbox.fill")
            summaryCard(title: settings.text(.downloaded), value: summaryValue { String($0.downloadedCount) }, symbol: "arrow.down.circle.fill")
            summaryCard(title: settings.text(.skipped), value: summaryValue { String($0.skippedCount) }, symbol: "forward.circle.fill")
            summaryCard(title: settings.text(.failed), value: summaryValue { String($0.failedCount) }, symbol: "exclamationmark.triangle.fill")
        }
    }

    private var controlsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    viewModel.run(
                        username: settings.trimmedUsername(),
                        token: settings.loadToken(),
                        destinationDirectory: settings.destinationURL(),
                        language: settings.language
                    )
                } label: {
                    Label(settings.text(viewModel.isRunning ? .downloading : .downloadRepositories), systemImage: viewModel.isRunning ? "hourglass" : "play.fill")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .disabled(viewModel.isRunning || settings.trimmedUsername().isEmpty || settings.hasStoredToken == false || settings.destinationURL() == nil)

                Button {
                    viewModel.cancel()
                } label: {
                    Label(settings.text(.cancel), systemImage: "stop.fill")
                        .frame(minWidth: 90)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
                .disabled(viewModel.isRunning == false)

                Button {
                    settings.chooseDestinationDirectory()
                } label: {
                    Label(settings.text(.chooseFolder), systemImage: "folder")
                        .frame(minWidth: 90)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)

                Button {
                    viewModel.copyOutput()
                } label: {
                    Label(settings.text(.copy), systemImage: "doc.on.doc")
                        .frame(minWidth: 90)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
                .disabled(viewModel.outputLines.isEmpty)

                Button {
                    viewModel.clearOutput()
                } label: {
                    Label(settings.text(.clear), systemImage: "trash")
                        .frame(minWidth: 90)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
                .disabled(viewModel.outputLines.isEmpty)

                Spacer()

                SettingsLink {
                    Label(settings.text(.settings), systemImage: "gearshape")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
            }

            if settings.trimmedUsername().isEmpty || settings.hasStoredToken == false || settings.destinationURL() == nil {
                Text(settings.text(.openSettingsHint))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(settings.text(.liveOutput))
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(settings.text(.selectableAutoScrolls))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            OutputLogView(lines: viewModel.outputLines, emptyStateText: settings.text(.outputEmpty))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var stateBadge: some View {
        Text(viewModel.runState.title(in: settings.language))
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(badgeBackground, in: Capsule())
    }

    private var badgeBackground: some ShapeStyle {
        switch viewModel.runState {
        case .idle:
            Color.white.opacity(0.12)
        case .running:
            Color.blue.opacity(0.30)
        case .succeeded:
            Color.green.opacity(0.30)
        case .failed:
            Color.red.opacity(0.30)
        case .cancelled:
            Color.orange.opacity(0.30)
        }
    }

    private func summaryCard(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func detailChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased(with: settings.language.locale))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryValue(_ transform: (RepositoryDownloadSummary) -> String) -> String {
        guard let summary = viewModel.lastSummary else {
            return "—"
        }
        return transform(summary)
    }
}
