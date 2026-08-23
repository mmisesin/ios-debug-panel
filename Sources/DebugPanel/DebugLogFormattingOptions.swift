import Foundation

public struct DebugLogFormattingOptions: Equatable, Sendable {
    public static let raw = DebugLogFormattingOptions(
        prettyPrintsJSON: false,
        normalizesHeaders: false
    )

    public static let beautified = DebugLogFormattingOptions()

    public var prettyPrintsJSON: Bool
    public var normalizesHeaders: Bool

    public init(
        prettyPrintsJSON: Bool = true,
        normalizesHeaders: Bool = true
    ) {
        self.prettyPrintsJSON = prettyPrintsJSON
        self.normalizesHeaders = normalizesHeaders
    }
}

extension DebugLogFormattingOptions {
    func format(label: String, value: String) -> String {
        switch label {
        case "Request Body", "Response Body":
            guard prettyPrintsJSON else {
                return value
            }
            return prettyPrintedJSON(value) ?? value
        case "Request Headers", "Response Headers":
            guard normalizesHeaders else {
                return value
            }
            return normalizedHeaders(value) ?? value
        default:
            return value
        }
    }

    private func prettyPrintedJSON(_ value: String) -> String? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            JSONSerialization.isValidJSONObject(object),
            let formattedData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
        else {
            return nil
        }

        return String(data: formattedData, encoding: .utf8)
    }

    private func normalizedHeaders(_ value: String) -> String? {
        let lines = value.split(whereSeparator: \Character.isNewline)
        guard lines.isEmpty == false else {
            return nil
        }

        let headers = lines.compactMap { line -> (name: String, value: String)? in
            guard let separator = line.firstIndex(of: ":") else {
                return nil
            }

            let name = line[..<separator].trimmingCharacters(in: .whitespaces)
            let headerValue = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            guard name.isEmpty == false else {
                return nil
            }

            return (name, headerValue)
        }

        guard headers.count == lines.count else {
            return nil
        }

        return headers
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .map { "\($0.name): \($0.value)" }
            .joined(separator: "\n")
    }
}
