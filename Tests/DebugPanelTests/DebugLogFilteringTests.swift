import Foundation
import Testing
@testable import DebugPanel

@Suite("Debug log filtering")
struct DebugLogFilteringTests {
    @Test("Filters by kind, level, and query across details")
    func filtersByKindLevelAndQuery() throws {
        let matching = DebugLogEntry(
            kind: .network,
            level: .warning,
            title: "GET 404",
            message: "https://api.example.com/v1/users/42?include=profile",
            details: [
                "Method": "GET",
                "URL": "https://api.example.com/v1/users/42?include=profile",
                "Status": "404",
                "Response Body": #"{"reason":"missing profile"}"#,
            ]
        )
        let wrongKind = DebugLogEntry(kind: .console, level: .warning, title: "UI", message: "missing profile")
        let wrongLevel = DebugLogEntry(kind: .network, level: .info, title: "GET 200", message: "https://api.example.com/v1/users")

        let filter = DebugLogFilter(query: "missing profile", kind: .network, level: .warning)

        #expect(filter.matches(matching))
        #expect(filter.matches(wrongKind) == false)
        #expect(filter.matches(wrongLevel) == false)
    }

    @Test("Empty query matches entries after trimming whitespace")
    func emptyQueryMatches() {
        let entry = DebugLogEntry(kind: .console, level: .info, title: "Console", message: "Ready")
        let filter = DebugLogFilter(query: "   ")

        #expect(filter.matches(entry))
    }

    @Test("Formats network row text for each display mode")
    func formatsNetworkRowText() {
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://api.example.com/v1/users/42?include=profile",
            details: [
                "URL": "https://api.example.com/v1/users/42?include=profile",
            ]
        )

        #expect(entry.listMessage(displayMode: .fullURL) == "https://api.example.com/v1/users/42?include=profile")
        #expect(entry.listMessage(displayMode: .hostAndPath) == "api.example.com/v1/users/42")
        #expect(entry.listMessage(displayMode: .pathAndQuery) == "/v1/users/42?include=profile")
        #expect(entry.listMessage(displayMode: .route) == "/v1/users/42")
    }

    @Test("Non-network rows always show the log message")
    func consoleRowsUseMessage() {
        let entry = DebugLogEntry(kind: .console, level: .info, title: "Console", message: "Loaded profile")

        #expect(entry.listMessage(displayMode: .route) == "Loaded profile")
    }
}
