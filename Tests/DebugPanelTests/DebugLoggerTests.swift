import Foundation
import Testing
@testable import DebugPanel

@Suite("DebugLogger")
struct DebugLoggerTests {
    @Test("Records console logs with category details")
    func recordsConsoleLogs() throws {
        let logger = DebugLogger()

        logger.recordConsole("Loaded profile", level: .debug, category: "Account")

        let entry = try #require(logger.entries.first)
        #expect(entry.kind == .console)
        #expect(entry.level == .debug)
        #expect(entry.title == "Account")
        #expect(entry.message == "Loaded profile")
        #expect(entry.details["Category"] == "Account")
    }

    @Test("Records successful network logs")
    func recordsNetworkLogs() throws {
        let logger = DebugLogger()
        let url = try #require(URL(string: "https://example.com/users"))

        logger.recordNetwork(
            method: "get",
            url: url,
            statusCode: 200,
            duration: 0.125,
            requestHeaders: ["Authorization": "Bearer token"],
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: #"{"ok":true}"#
        )

        let entry = try #require(logger.entries.first)
        #expect(entry.kind == .network)
        #expect(entry.level == .info)
        #expect(entry.title == "GET 200")
        #expect(entry.message == "https://example.com/users")
        #expect(entry.details["Method"] == "GET")
        #expect(entry.details["Status"] == "200")
        #expect(entry.details["Duration"] == "125 ms")
        #expect(entry.details["Response Body"] == #"{"ok":true}"#)
    }

    @Test("Marks network errors as error logs")
    func recordsNetworkErrors() throws {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "Request failed" }
        }

        let logger = DebugLogger()
        let url = try #require(URL(string: "https://example.com/fail"))

        logger.recordNetwork(method: "post", url: url, error: SampleError())

        let entry = try #require(logger.entries.first)
        #expect(entry.level == .error)
        #expect(entry.details["Error"] == "Request failed")
    }

    @Test("Marks 4xx and 5xx network responses as warnings")
    func recordsHTTPFailuresAsWarnings() throws {
        let logger = DebugLogger()
        let url = try #require(URL(string: "https://example.com/missing"))

        logger.recordNetwork(method: "GET", url: url, statusCode: 404)

        let entry = try #require(logger.entries.first)
        #expect(entry.level == .warning)
        #expect(entry.title == "GET 404")
    }

    @Test("Trims old entries when the max entry count is reached")
    func trimsOldEntries() {
        let logger = DebugLogger(maxEntryCount: 2)

        logger.recordConsole("First")
        logger.recordConsole("Second")
        logger.recordConsole("Third")

        #expect(logger.entries.map(\.message) == ["Second", "Third"])
    }

    @Test("Clears recorded entries")
    func clearsEntries() {
        let logger = DebugLogger()

        logger.recordConsole("One")
        logger.clear()

        #expect(logger.entries.isEmpty)
    }
}
