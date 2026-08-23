import SwiftUI

public struct DebugPanelView: View {
    private let logger: DebugLogger
    private let formattingOptions: DebugLogFormattingOptions

    @State private var entries: [DebugLogEntry]
    @State private var selectedKind = LogKindFilter.all
    @State private var selectedLevel = LogLevelFilter.all
    @State private var selectedEntry: DebugLogEntry?
    @State private var query = ""
    @State private var listDisplayMode = DebugLogListDisplayMode.route

    public init(
        logger: DebugLogger = .shared,
        formattingOptions: DebugLogFormattingOptions = .raw
    ) {
        self.logger = logger
        self.formattingOptions = formattingOptions
        self._entries = State(initialValue: logger.entries)
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedEntry) {
                ForEach(filteredEntries) { entry in
                    LogEntryRow(entry: entry, displayMode: listDisplayMode)
                        .tag(entry)
                }
            }
            .navigationTitle("Debug Logs")
            .searchable(text: $query, prompt: "Search logs")
            .toolbar {
                ToolbarItemGroup {
                    LogFilterMenu(
                        selectedKind: $selectedKind,
                        selectedLevel: $selectedLevel,
                        hasActiveFilters: hasActiveFilters,
                        reset: resetFilters
                    )

                    LogViewMenu(listDisplayMode: $listDisplayMode)
                }

                ToolbarItem {
                    Button("Clear", systemImage: "trash") {
                        logger.clear()
                        selectedEntry = nil
                    }
                    .disabled(entries.isEmpty)
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Logs",
                        systemImage: "text.bubble",
                        description: Text("Recorded console and network logs appear here.")
                    )
                } else if filteredEntries.isEmpty {
                    ContentUnavailableView.search(text: query.isEmpty ? "selected filters" : query)
                }
            }
        } detail: {
            if let selectedEntry {
                LogEntryDetail(entry: selectedEntry, formattingOptions: formattingOptions)
            } else {
                ContentUnavailableView(
                    "Select a Log",
                    systemImage: "sidebar.left",
                    description: Text("Choose an entry to inspect its details.")
                )
            }
        }
        .task {
            for await snapshot in logger.snapshots() {
                entries = snapshot
                if let selectedEntry, snapshot.contains(selectedEntry) == false {
                    self.selectedEntry = nil
                }
            }
        }
    }

    private var filteredEntries: [DebugLogEntry] {
        let filter = DebugLogFilter(query: query, kind: selectedKind.kind, level: selectedLevel.level)

        return Array(entries
            .filter { filter.matches($0) }
            .reversed())
    }

    private var hasActiveFilters: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
            selectedKind != .all ||
            selectedLevel != .all
    }

    private func resetFilters() {
        query = ""
        selectedKind = .all
        selectedLevel = .all
    }
}

private enum LogKindFilter: String, CaseIterable, Identifiable {
    case all
    case console
    case network

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .console:
            "Console"
        case .network:
            "Network"
        }
    }

    var kind: DebugLogEntry.Kind? {
        switch self {
        case .all:
            nil
        case .console:
            .console
        case .network:
            .network
        }
    }
}

private enum LogLevelFilter: String, CaseIterable, Identifiable {
    case all
    case debug
    case info
    case warning
    case error

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "Any Level"
        case .debug:
            "Debug"
        case .info:
            "Info"
        case .warning:
            "Warning"
        case .error:
            "Error"
        }
    }

    var level: DebugLogEntry.Level? {
        switch self {
        case .all:
            nil
        case .debug:
            .debug
        case .info:
            .info
        case .warning:
            .warning
        case .error:
            .error
        }
    }
}

private struct LogFilterMenu: View {
    @Binding var selectedKind: LogKindFilter
    @Binding var selectedLevel: LogLevelFilter
    let hasActiveFilters: Bool
    let reset: () -> Void

    var body: some View {
        Menu("Filters", systemImage: "line.3.horizontal.decrease.circle") {
            Picker("Type", selection: $selectedKind) {
                ForEach(LogKindFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }

            Picker("Level", selection: $selectedLevel) {
                ForEach(LogLevelFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }

            if hasActiveFilters {
                Button("Reset Filters", systemImage: "xmark.circle", action: reset)
            }
        }
    }
}

private struct LogViewMenu: View {
    @Binding var listDisplayMode: DebugLogListDisplayMode

    var body: some View {
        Menu("View", systemImage: "eye") {
            Picker("Network Row Text", selection: $listDisplayMode) {
                ForEach(DebugLogListDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        }
    }
}

private struct LogEntryRow: View {
    let entry: DebugLogEntry
    let displayMode: DebugLogListDisplayMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: entry.kind == .network ? "arrow.left.arrow.right" : "terminal")
                    .foregroundStyle(entry.level.tint)

                Text(entry.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(entry.listMessage(displayMode: displayMode))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private extension DebugLogEntry.Level {
    var tint: Color {
        switch self {
        case .debug:
            .secondary
        case .info:
            .blue
        case .warning:
            .orange
        case .error:
            .red
        }
    }

}
