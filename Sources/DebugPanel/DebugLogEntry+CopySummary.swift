import Foundation

public extension DebugLogEntry {
    var copySummary: String {
        var lines = [
            "\(kind.displayName) Log",
            "Title: \(title)",
            "Level: \(level.displayName)",
            "Time: \(formattedDate)",
            "Message: \(message)",
        ]

        if !details.isEmpty {
            lines.append("")
            lines.append("Details:")
            lines.append(contentsOf: summaryDetailLines)
        }

        return lines.joined(separator: "\n")
    }

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private var summaryDetailLines: [String] {
        let preferredKeys = [
            "Method",
            "URL",
            "Status",
            "Duration",
            "Request Headers",
            "Request Body",
            "Response Headers",
            "Response Body",
            "Error",
            "Category",
        ]

        let preferredLines = preferredKeys.compactMap { key -> String? in
            guard let value = details[key] else {
                return nil
            }
            return formattedDetailLine(key: key, value: value)
        }

        let remainingLines = details.keys
            .filter { preferredKeys.contains($0) == false }
            .sorted()
            .compactMap { key in
                details[key].map { formattedDetailLine(key: key, value: $0) }
            }

        return preferredLines + remainingLines
    }

    private func formattedDetailLine(key: String, value: String) -> String {
        if value.contains("\n") {
            return "\(key):\n\(value)"
        }
        return "\(key): \(value)"
    }
}

private extension DebugLogEntry.Kind {
    var displayName: String {
        switch self {
        case .console:
            "Console"
        case .network:
            "Network"
        }
    }
}

private extension DebugLogEntry.Level {
    var displayName: String {
        switch self {
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
}
