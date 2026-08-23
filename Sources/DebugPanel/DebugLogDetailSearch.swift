import Foundation

public struct DebugLogDetailField: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let value: String

    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }

    public func matches(_ query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            return false
        }

        return label.localizedCaseInsensitiveContains(trimmedQuery) ||
            value.localizedCaseInsensitiveContains(trimmedQuery)
    }
}

public extension DebugLogEntry {
    var detailSummaryFields: [DebugLogDetailField] {
        [
            DebugLogDetailField(id: "summary.type", label: "Type", value: kind.rawValue.capitalized),
            DebugLogDetailField(id: "summary.level", label: "Level", value: level.rawValue.capitalized),
            DebugLogDetailField(id: "summary.time", label: "Time", value: date.formatted(date: .abbreviated, time: .standard)),
            DebugLogDetailField(id: "summary.message", label: "Message", value: message),
        ]
    }

    var detailFields: [DebugLogDetailField] {
        detailFields(formattingOptions: .raw)
    }

    func detailFields(formattingOptions: DebugLogFormattingOptions) -> [DebugLogDetailField] {
        details
            .sorted(by: { $0.key < $1.key })
            .map { key, value in
                DebugLogDetailField(
                    id: "detail.\(key)",
                    label: key,
                    value: formattingOptions.format(label: key, value: value)
                )
            }
    }

    func firstDetailMatchID(query: String) -> String? {
        firstDetailMatchID(query: query, formattingOptions: .raw)
    }

    func firstDetailMatchID(
        query: String,
        formattingOptions: DebugLogFormattingOptions
    ) -> String? {
        (detailSummaryFields + detailFields(formattingOptions: formattingOptions))
            .first { $0.matches(query) }?
            .id
    }
}
