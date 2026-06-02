import Foundation
import Testing
@testable import DebugPanel

@Suite("DebugLogEntry copy summary")
struct DebugLogEntrySummaryTests {
    @Test("Builds network summaries in request and response order")
    func buildsNetworkSummary() {
        let entry = DebugLogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            date: Date(timeIntervalSince1970: 1_700_000_000.125),
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com/users",
            details: [
                "Response Body": #"{"ok":true}"#,
                "Method": "GET",
                "Duration": "125 ms",
                "Status": "200",
                "URL": "https://example.com/users",
                "Request Headers": "Authorization: Bearer token",
                "Response Headers": "Content-Type: application/json",
            ]
        )

        #expect(
            entry.copySummary == """
            Network Log
            Title: GET 200
            Level: Info
            Time: 2023-11-14T22:13:20.125Z
            Message: https://example.com/users

            Details:
            Method: GET
            URL: https://example.com/users
            Status: 200
            Duration: 125 ms
            Request Headers: Authorization: Bearer token
            Response Headers: Content-Type: application/json
            Response Body: {"ok":true}
            """
        )
    }

    @Test("Builds console summaries with custom details sorted after category")
    func buildsConsoleSummary() {
        let entry = DebugLogEntry(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            kind: .console,
            level: .debug,
            title: "Account",
            message: "Loaded profile",
            details: [
                "Category": "Account",
                "User ID": "42",
                "Screen": "Profile",
            ]
        )

        #expect(
            entry.copySummary == """
            Console Log
            Title: Account
            Level: Debug
            Time: 2023-11-14T22:13:20.000Z
            Message: Loaded profile

            Details:
            Category: Account
            Screen: Profile
            User ID: 42
            """
        )
    }
}
