import SwiftUI

struct OutputLogView: View {
    private struct ScrollTrigger: Equatable {
        let lineCount: Int
        let lastLine: String?
        let contentSize: CGSize
        let viewportSize: CGSize
    }

    private struct ContentSizePreferenceKey: PreferenceKey {
        static let defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }

    let lines: [String]
    let emptyStateText: String
    private let bottomAnchorID = "output-log-bottom-anchor"
    @State private var contentSize: CGSize = .zero
 
    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { viewport in
                  ScrollView {
                      // Eager layout keeps the bottom anchor accurate for wrapped log lines.
                      VStack(alignment: .leading, spacing: 6) {
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
                                   .padding(.bottom, 18)
                                   .id(bottomAnchorID)
                    }
    .textSelection(.enabled)
      .padding([.top, .horizontal], 18)
      .background {
          GeometryReader { geometry in
              Color.clear.preference(
                  key: ContentSizePreferenceKey.self,
                  value: geometry.size
              )
          }
                    }
                }
                   //                .defaultScrollAnchor(contentSize.height > viewport.size.height ? .bottom : .top)
                                   .defaultScrollAnchor(.bottomTrailing)
                                   .defaultScrollAnchor(.trailing)
                                   .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                   .onPreferenceChange(ContentSizePreferenceKey.self) { size in
                                       contentSize = size
                                   }
                                   .task(id: ScrollTrigger(
                                       lineCount: lines.count,
                                       lastLine: lines.last,
                                       contentSize: contentSize,
                                       viewportSize: viewport.size
                                   )) {
                                       // New output or completed layout cancels any stale scroll request.
                                       await Task.yield()
                                       guard !Task.isCancelled else {
                                           return
                                       }
                                       proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                }
            }
        }
    }
}
