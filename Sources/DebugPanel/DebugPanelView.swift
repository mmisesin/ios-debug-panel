import SwiftUI

public struct DebugPanelView: View {
    private let logger: DebugLogger

    @State private var entries: [DebugLogEntry]
    @State private var selectedKind: DebugLogEntry.Kind?
    @State private var selectedEntry: DebugLogEntry?

    public init(logger: DebugLogger = .shared) {
        self.logger = logger
        self._entries = State(initialValue: logger.entries)
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedEntry) {
                ForEach(filteredEntries) { entry in
                    LogEntryRow(entry: entry)
                        .tag(entry)
                }
            }
            .navigationTitle("Debug Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Log type", selection: $selectedKind) {
                        Text("All").tag(nil as DebugLogEntry.Kind?)
                        Text("Console").tag(DebugLogEntry.Kind?.some(.console))
                        Text("Network").tag(DebugLogEntry.Kind?.some(.network))
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
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
                }
            }
        } detail: {
            if let selectedEntry {
                LogEntryDetail(entry: selectedEntry)
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
        entries
            .filter { entry in
                guard let selectedKind else {
                    return true
                }
                return entry.kind == selectedKind
            }
            .reversed()
    }
}

private struct LogEntryRow: View {
    let entry: DebugLogEntry

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

            Text(entry.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private struct LogEntryDetail: View {
    let entry: DebugLogEntry

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Type", value: entry.kind.rawValue.capitalized)
                LabeledContent("Level", value: entry.level.rawValue.capitalized)
                LabeledContent("Time", value: entry.date.formatted(date: .abbreviated, time: .standard))
                LabeledContent("Message", value: entry.message)
            }

            if !entry.details.isEmpty {
                Section("Details") {
                    ForEach(entry.details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(key)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(value)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(entry.title)
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
