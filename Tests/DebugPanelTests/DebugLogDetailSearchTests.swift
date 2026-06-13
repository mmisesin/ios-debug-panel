import Foundation
import Testing
@testable import DebugPanel

@Suite("Debug log detail search")
struct DebugLogDetailSearchTests {
    @Test("Finds first match in summary fields before detail fields")
    func findsFirstSummaryMatch() {
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com/profile",
            details: ["Response Body": #"{"profile":true}"#]
        )

        #expect(entry.firstDetailMatchID(query: "profile") == "summary.message")
    }

    @Test("Finds matches in detail payload values")
    func findsPayloadMatch() {
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com/users",
            details: [
                "Response Body": #"{"user":{"name":"Artem"}}"#,
            ]
        )

        #expect(entry.firstDetailMatchID(query: "artem") == "detail.Response Body")
    }

    @Test("Finds matches in detail field labels")
    func findsFieldLabelMatch() {
        let field = DebugLogDetailField(id: "detail.Request Body", label: "Request Body", value: #"{"id":42}"#)

        #expect(field.matches("request"))
        #expect(field.matches("missing") == false)
    }

    @Test("Blank queries do not match")
    func blankQueriesDoNotMatch() {
        let entry = DebugLogEntry(kind: .console, level: .info, title: "Console", message: "Ready")

        #expect(entry.firstDetailMatchID(query: "   ") == nil)
    }
}
