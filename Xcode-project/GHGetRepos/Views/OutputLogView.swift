import SwiftUI

struct OutputLogView: View {
    let lines: [String]
    let emptyStateText: String
    private let bottomAnchorID = "output-log-bottom-anchor"
    @State private var scrollTarget: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                if lines.isEmpty {
                    Text(emptyStateText)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } else {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(verbatim: line)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("line-\(index)")
                    }
                }
                Color.clear
                    .frame(height: 1)
                    .id(bottomAnchorID)
            }
            .scrollTargetLayout()
            .textSelection(.enabled)
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .scrollPosition(id: $scrollTarget, anchor: .bottom)
        .onChange(of: lines.count) { _, _ in
            scrollToBottom()
        }
        .onAppear {
            scrollToBottom()
        }
    }

    private func scrollToBottom() {
        Task { @MainActor in
            scrollTarget = nil
            await Task.yield()
            scrollTarget = bottomAnchorID
        }
    }
}
