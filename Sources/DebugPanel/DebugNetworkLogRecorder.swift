import Foundation

@_spi(Internal) public struct DebugNetworkLogRecorder {
    public let logger: DebugLogger
    public let options: DebugNetworkLoggingOptions

    public init(logger: DebugLogger = .shared) {
        self.init(logger: logger, options: DebugPanelSDK.activeNetworkLoggingOptions)
    }

    public init(logger: DebugLogger, options: DebugNetworkLoggingOptions) {
        self.logger = logger
        self.options = options
    }

    public func record(
        request: URLRequest,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?,
        startDate: Date,
        endDate: Date = Date()
    ) {
        guard let url = request.url else {
            return
        }

        logger.recordNetwork(
            method: request.httpMethod ?? "GET",
            url: url,
            statusCode: response?.statusCode,
            duration: endDate.timeIntervalSince(startDate),
            requestHeaders: formattedRequestHeaders(from: request),
            responseHeaders: formattedResponseHeaders(from: response),
            requestBody: bodyString(from: request.httpBody),
            responseBody: bodyString(from: data),
            error: error,
            date: startDate
        )
    }

    private func formattedRequestHeaders(from request: URLRequest) -> [String: String] {
        guard options.capturesHeaders else {
            return [:]
        }

        return redact(request.allHTTPHeaderFields ?? [:])
    }

    private func formattedResponseHeaders(from response: HTTPURLResponse?) -> [String: String] {
        guard options.capturesHeaders, let response else {
            return [:]
        }

        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            headers[String(describing: key)] = String(describing: value)
        }
        return redact(headers)
    }

    private func redact(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [:]) { result, pair in
            let shouldRedact = options.redactedHeaders.contains { redactedHeader in
                redactedHeader.compare(pair.key, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
            result[pair.key] = shouldRedact ? "[REDACTED]" : pair.value
        }
    }

    private func bodyString(from data: Data?) -> String? {
        guard options.capturesBodies, let data, data.isEmpty == false else {
            return nil
        }

        let cappedData = data.prefix(options.maxBodyBytes)
        let suffix = data.count > cappedData.count ? "\n[truncated \(data.count - cappedData.count) bytes]" : ""

        if let text = String(data: Data(cappedData), encoding: .utf8) {
            return text + suffix
        }

        return "<\(data.count) bytes binary body>" + suffix
    }
}
