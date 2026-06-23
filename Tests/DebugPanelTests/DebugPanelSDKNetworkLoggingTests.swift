import Foundation
import Testing
@testable import DebugPanel

@Suite("Automatic URLSession network logging", .serialized)
struct DebugPanelSDKNetworkLoggingTests {
    @Test("Instrumenting URLSessionConfiguration inserts logging protocol once and preserves existing classes")
    func instrumentsConfigurationOnce() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NetworkLoggingStubURLProtocol.self]

        let once = DebugPanelSDK.instrument(configuration)
        let twice = DebugPanelSDK.instrument(once)

        let classes = twice.protocolClasses ?? []
        #expect(classes.first == DebugNetworkLoggingURLProtocol.self)
        #expect(classes.contains { $0 == NetworkLoggingStubURLProtocol.self })
        #expect(classes.filter { $0 == DebugNetworkLoggingURLProtocol.self }.count == 1)
    }

    @Test("Automatic logging toggle updates enabled and registration state")
    func togglesAutomaticLogging() {
        resetState()

        DebugPanelSDK.automaticNetworkLoggingEnabled = true
        #expect(DebugPanelSDK.isNetworkLoggingEnabled)
        #expect(DebugPanelSDK.isBestEffortRegisteredForTesting)

        DebugPanelSDK.automaticNetworkLoggingEnabled = true
        #expect(DebugPanelSDK.isNetworkLoggingEnabled)
        #expect(DebugPanelSDK.isBestEffortRegisteredForTesting)

        DebugPanelSDK.automaticNetworkLoggingEnabled = false
        #expect(DebugPanelSDK.isNetworkLoggingEnabled == false)
        #expect(DebugPanelSDK.isBestEffortRegisteredForTesting == false)
    }

    @Test("Disabled logging lets requests pass without recording")
    func disabledLoggingDoesNotRecord() async throws {
        resetState()
        NetworkLoggingStubURLProtocol.response = .success(statusCode: 204, data: Data())

        let session = makeSession()
        let url = try #require(URL(string: "https://example.com/disabled"))
        _ = try await session.data(from: url)

        #expect(DebugLogger.shared.entries.isEmpty)
    }

    @Test("Logs URLSession metadata with redacted headers and no bodies by default")
    func logsMetadataWithRedaction() async throws {
        resetState()
        DebugPanelSDK.automaticNetworkLoggingEnabled = true
        NetworkLoggingStubURLProtocol.response = .success(
            statusCode: 200,
            data: Data(#"{"ok":true}"#.utf8),
            headers: ["Set-Cookie": "session=secret"]
        )

        var request = URLRequest(url: try #require(URL(string: "https://example.com/users")))
        request.httpMethod = "POST"
        request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
        request.httpBody = Data(#"{"name":"Artem"}"#.utf8)

        let session = makeSession()
        let (data, _) = try await session.data(for: request)

        #expect(String(data: data, encoding: .utf8) == #"{"ok":true}"#)
        let entry = try #require(DebugLogger.shared.entries.first)
        #expect(entry.kind == .network)
        #expect(entry.level == .info)
        #expect(entry.title == "POST 200")
        #expect(entry.details["Request Headers"]?.contains("Authorization: [REDACTED]") == true)
        #expect(entry.details["Response Headers"]?.contains("Set-Cookie: [REDACTED]") == true)
        #expect(entry.details["Request Body"] == nil)
        #expect(entry.details["Response Body"] == nil)
    }

    @Test("Logs HTTP failures as warnings")
    func logsHTTPFailures() async throws {
        resetState()
        DebugPanelSDK.automaticNetworkLoggingEnabled = true
        NetworkLoggingStubURLProtocol.response = .success(statusCode: 500, data: Data("nope".utf8))

        let session = makeSession()
        let url = try #require(URL(string: "https://example.com/failure"))
        _ = try await session.data(from: url)

        let entry = try #require(DebugLogger.shared.entries.first)
        #expect(entry.level == .warning)
        #expect(entry.details["Status"] == "500")
    }

    @Test("Logs transport errors")
    func logsTransportErrors() async throws {
        resetState()
        DebugPanelSDK.automaticNetworkLoggingEnabled = true
        NetworkLoggingStubURLProtocol.response = .failure(URLError(.timedOut))

        let session = makeSession()
        let url = try #require(URL(string: "https://example.com/timeout"))

        await #expect(throws: URLError.self) {
            _ = try await session.data(from: url)
        }

        let entry = try #require(DebugLogger.shared.entries.first)
        #expect(entry.level == .error)
        #expect(entry.details["Error"]?.isEmpty == false)
    }

    @Test("Captures capped response bodies when enabled")
    func capturesCappedResponseBodies() async throws {
        resetState()
        DebugPanelSDK.automaticNetworkLoggingEnabled = true
        DebugPanelSDK.networkLoggingOptions = DebugNetworkLoggingOptions(capturesBodies: true, maxBodyBytes: 5)
        NetworkLoggingStubURLProtocol.response = .success(statusCode: 200, data: Data("hello world".utf8))

        var request = URLRequest(url: try #require(URL(string: "https://example.com/body")))
        request.httpMethod = "PUT"
        request.httpBodyStream = InputStream(data: Data("abcdefghi".utf8))

        let session = makeSession()
        _ = try await session.data(for: request)

        let entry = try #require(DebugLogger.shared.entries.first)
        #expect(entry.details["Request Body"] == nil)
        #expect(entry.details["Response Body"] == "hello\n[truncated 6 bytes]")
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [
            DebugNetworkLoggingURLProtocol.self,
            NetworkLoggingStubURLProtocol.self,
        ]

        DebugNetworkLoggingURLProtocol.forwardingConfigurationProvider = {
            let forwardingConfiguration = URLSessionConfiguration.ephemeral
            forwardingConfiguration.protocolClasses = [NetworkLoggingStubURLProtocol.self]
            return forwardingConfiguration
        }

        return URLSession(configuration: configuration)
    }

    private func resetState() {
        DebugLogger.shared.clear()
        DebugPanelSDK.automaticNetworkLoggingEnabled = false
        DebugPanelSDK.resetForTesting()
        DebugNetworkLoggingURLProtocol.resetForTesting()
        NetworkLoggingStubURLProtocol.response = .success(statusCode: 200, data: Data())
    }
}

private final class NetworkLoggingStubURLProtocol: URLProtocol, @unchecked Sendable {
    enum StubResponse {
        case success(statusCode: Int, data: Data, headers: [String: String] = [:])
        case failure(Error)
    }

    nonisolated(unsafe) static var response: StubResponse = .success(statusCode: 200, data: Data())

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        switch Self.response {
        case let .success(statusCode, data, headers):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if data.isEmpty == false {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
