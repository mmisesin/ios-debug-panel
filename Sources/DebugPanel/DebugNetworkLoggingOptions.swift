import Foundation

public struct DebugNetworkLoggingOptions: Equatable, Sendable {
    public static let metadataOnly = DebugNetworkLoggingOptions()

    public var capturesHeaders: Bool
    public var capturesBodies: Bool
    public var maxBodyBytes: Int
    public var redactedHeaders: Set<String>

    public init(
        capturesHeaders: Bool = true,
        capturesBodies: Bool = false,
        maxBodyBytes: Int = 32_768,
        redactedHeaders: Set<String> = ["Authorization", "Cookie", "Set-Cookie"]
    ) {
        self.capturesHeaders = capturesHeaders
        self.capturesBodies = capturesBodies
        self.maxBodyBytes = max(0, maxBodyBytes)
        self.redactedHeaders = redactedHeaders
    }
}
