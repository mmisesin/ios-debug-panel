import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct LogEntryDetail: View {
    let entry: DebugLogEntry

    @State private var copied = false
    @State private var detailQuery = ""

    var body: some View {
        ScrollViewReader { proxy in
            detailList
                .onChange(of: firstMatchID) { _, matchID in
                    guard let matchID else {
                        return
                    }

                    withAnimation {
                        proxy.scrollTo(matchID, anchor: .center)
                    }
                }
        }
        .navigationTitle(entry.title)
        .onChange(of: entry.id) { _, _ in
            detailQuery = ""
        }
        .toolbar {
            ToolbarItem {
                Button(copied ? "Copied" : "Copy Summary", systemImage: copied ? "checkmark" : "doc.on.doc") {
                    DebugClipboard.copy(entry.copySummary)
                    copied = true

                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        copied = false
                    }
                }
            }
        }
    }

    private var detailList: some View {
        List {
            Section("Summary") {
                ForEach(entry.detailSummaryFields) { field in
                    DetailFieldRow(field: field, query: detailQuery, isFocused: field.id == firstMatchID)
                        .id(field.id)
                }
            }

            if !entry.detailFields.isEmpty {
                Section("Details") {
                    ForEach(entry.detailFields) { field in
                        DetailFieldRow(field: field, query: detailQuery, isFocused: field.id == firstMatchID)
                            .id(field.id)
                    }
                }
            }
        }
        .searchable(text: $detailQuery, prompt: "Search this log")
        .overlay {
            if searchHasNoMatches {
                ContentUnavailableView.search(text: detailQuery)
            }
        }
    }

    private var firstMatchID: String? {
        entry.firstDetailMatchID(query: detailQuery)
    }

    private var searchHasNoMatches: Bool {
        detailQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
            firstMatchID == nil
    }
}

private struct DetailFieldRow: View {
    let field: DebugLogDetailField
    let query: String
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HighlightedText(text: field.label, query: query)
                .font(.caption)
                .foregroundStyle(.secondary)

            HighlightedText(text: field.value, query: query)
                .font(.body.monospaced())
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
        .listRowBackground(isFocused ? Color.yellow.opacity(0.16) : nil)
    }
}

private struct HighlightedText: View {
    let text: String
    let query: String

    var body: some View {
        Text(highlightedString)
    }

    private var highlightedString: AttributedString {
        var attributed = AttributedString(text)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            return attributed
        }

        for range in text.caseInsensitiveRanges(of: trimmedQuery) {
            guard
                let lowerBound = AttributedString.Index(range.lowerBound, within: attributed),
                let upperBound = AttributedString.Index(range.upperBound, within: attributed)
            else {
                continue
            }

            attributed[lowerBound..<upperBound].backgroundColor = .yellow.opacity(0.55)
            attributed[lowerBound..<upperBound].foregroundColor = .primary
        }

        return attributed
    }
}

private enum DebugClipboard {
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

private extension String {
    func caseInsensitiveRanges(of query: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = startIndex

        while searchStart < endIndex,
              let range = self.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<endIndex
              ) {
            ranges.append(range)
            searchStart = range.upperBound
        }

        return ranges
    }
}
