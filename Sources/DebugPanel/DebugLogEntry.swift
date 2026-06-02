import Foundation

public struct DebugLogEntry: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Equatable, Sendable {
        case console
        case network
    }

    public enum Level: String, CaseIterable, Equatable, Sendable {
        case debug
        case info
        case warning
        case error
    }

    public let id: UUID
    public let date: Date
    public let kind: Kind
    public let level: Level
    public let title: String
    public let message: String
    public let details: [String: String]

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        kind: Kind,
        level: Level,
        title: String,
        message: String,
        details: [String: String] = [:]
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.level = level
        self.title = title
        self.message = message
        self.details = details
    }
}
