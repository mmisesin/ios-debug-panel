import Foundation
import Testing
@testable import DebugPanel
@testable import DebugPanelAlamofire

@Suite("Alamofire automatic network logging", .serialized)
struct DebugPanelAlamofireEventMonitorTests {
    @Test("Maps completed Alamofire metadata into DebugLogger")
    func recordsCompletedRequestMetadata() throws {
        resetState()
        let monitor = DebugPanelAlamofireEventMonitor()
        var request = URLRequest(url: try #require(URL(string: "https://example.com/alamofire")))
        request.httpMethod = "GET"
        request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
        let response = HTTPURLResponse(
            url: try #require(request.url),
            statusCode: 202,
            httpVersion: "HTTP/1.1",
            headerFields: ["Set-Cookie": "session=secret"]
        )

        monitor.recordCompletedRequest(
            urlRequest: request,
            httpResponse: response,
            data: Data(#"{"ok":true}"#.utf8),
            error: nil,
            startDate: Date(timeIntervalSince1970: 100),
            endDate: Date(timeIntervalSince1970: 101)
        )

        let entry = try #require(DebugLogger.shared.entries.first)
        #expect(entry.title == "GET 202")
        #expect(entry.details["Duration"] == "1000 ms")
        #expect(entry.details["Request Headers"]?.contains("Authorization: [REDACTED]") == true)
        #expect(entry.details["Response Headers"]?.contains("Set-Cookie: [REDACTED]") == true)
        #expect(entry.details["Response Body"] == nil)
    }

    @Test("Uses shared body capture options")
    func recordsBodiesWhenEnabled() throws {
        resetState()
        DebugPanelSDK.networkLoggingOptions = DebugNetworkLoggingOptions(capturesBodies: true, maxBodyBytes: 4)
        let monitor = DebugPanelAlamofireEventMonitor()
        var request = URLRequest(url: try #require(URL(string: "https://example.com/alamofire-body")))
        request.httpMethod = "POST"
        request.httpBody = Data("abcdef".utf8)

        monitor.recordCompletedRequest(
            urlRequest: request,
            httpResponse: nil,
            data: Data("response".utf8),
            error: nil,
            startDate: Date(timeIntervalSince1970: 100),
            endDate: Date(timeIntervalSince1970: 100.5)
        )

        let entry = try #require(DebugLogger.shared.entries.first)
        #expect(entry.details["Request Body"] == "abcd\n[truncated 2 bytes]")
        #expect(entry.details["Response Body"] == "resp\n[truncated 4 bytes]")
    }

    private func resetState() {
        DebugLogger.shared.clear()
        DebugPanelSDK.networkLoggingOptions = .metadataOnly
    }
}
