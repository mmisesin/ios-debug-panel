import Foundation
import Testing
@testable import DebugPanel

@Suite("Debug log formatting options")
struct DebugLogFormattingOptionsTests {
    @Test("Beautified formatting pretty-prints JSON bodies")
    func prettyPrintsJSONBodies() throws {
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com/users",
            details: ["Response Body": #"{"user":{"id":42,"name":"Artem"},"active":true}"#]
        )

        let responseBody = try #require(
            entry.detailFields(formattingOptions: .beautified)
                .first { $0.label == "Response Body" }?
                .value
        )

        #expect(
            responseBody == """
            {
              "active" : true,
              "user" : {
                "id" : 42,
                "name" : "Artem"
              }
            }
            """
        )
    }

    @Test("Beautified formatting normalizes and sorts headers")
    func normalizesHeaders() throws {
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com/users",
            details: [
                "Response Headers": "X-Request-ID: 42\n content-type : application/json\nCache-Control:no-cache",
            ]
        )

        let responseHeaders = try #require(
            entry.detailFields(formattingOptions: .beautified)
                .first { $0.label == "Response Headers" }?
                .value
        )

        #expect(
            responseHeaders == """
            Cache-Control: no-cache
            content-type: application/json
            X-Request-ID: 42
            """
        )
    }

    @Test("Raw formatting preserves captured values")
    func rawFormattingPreservesValues() throws {
        let body = #"{"ok":true}"#
        let headers = "Z-Header: last\nA-Header:first"
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com",
            details: [
                "Request Body": body,
                "Request Headers": headers,
                "Response Body": body,
                "Response Headers": headers,
            ]
        )

        let fields = entry.detailFields(formattingOptions: .raw)

        #expect(fields.first { $0.label == "Request Body" }?.value == body)
        #expect(fields.first { $0.label == "Request Headers" }?.value == headers)
        #expect(fields.first { $0.label == "Response Body" }?.value == body)
        #expect(fields.first { $0.label == "Response Headers" }?.value == headers)
        #expect(entry.copySummary == entry.copySummary(formattingOptions: .raw))
    }

    @Test("JSON and header formatting can be configured independently")
    func independentlyConfiguresFormatting() throws {
        let body = #"{"ok":true}"#
        let headers = "Z-Header: last\nA-Header:first"
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com",
            details: [
                "Response Body": body,
                "Response Headers": headers,
            ]
        )
        let options = DebugLogFormattingOptions(
            prettyPrintsJSON: false,
            normalizesHeaders: true
        )

        let fields = entry.detailFields(formattingOptions: options)

        #expect(fields.first { $0.label == "Response Body" }?.value == body)
        #expect(fields.first { $0.label == "Response Headers" }?.value == "A-Header: first\nZ-Header: last")
    }

    @Test("Malformed structured values fall back to the captured text")
    func malformedValuesRemainRaw() throws {
        let malformedJSON = #"{"unfinished":true"#
        let malformedHeaders = "Content-Type: application/json\ncontinuation without a name"
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com",
            details: [
                "Request Body": malformedJSON,
                "Request Headers": malformedHeaders,
            ]
        )

        let fields = entry.detailFields(formattingOptions: .beautified)

        #expect(fields.first { $0.label == "Request Body" }?.value == malformedJSON)
        #expect(fields.first { $0.label == "Request Headers" }?.value == malformedHeaders)
    }

    @Test("Copy summaries use beautified values")
    func copySummaryUsesBeautifiedValues() {
        let entry = DebugLogEntry(
            kind: .network,
            level: .info,
            title: "GET 200",
            message: "https://example.com",
            details: ["Response Body": #"{"ok":true}"#]
        )

        #expect(
            entry.copySummary(formattingOptions: .beautified).contains(
                """
                Response Body:
                {
                  "ok" : true
                }
                """
            )
        )
    }
}
