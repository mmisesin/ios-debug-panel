import Foundation

public final class DebugNetworkLoggingURLProtocol: URLProtocol, @unchecked Sendable {
    private static let handledKey = "DebugPanel.DebugNetworkLoggingURLProtocol.handled"
    private static let forwardingState = ForwardingState()

    private var dataTask: URLSessionDataTask?
    private var forwardingSession: URLSession?
    private var loggedRequest: URLRequest?
    private var startDate: Date?

    static var forwardingConfigurationProvider: @Sendable () -> URLSessionConfiguration {
        get {
            forwardingState.lock.withLock { forwardingState.provider }
        }
        set {
            forwardingState.lock.withLock {
                forwardingState.provider = newValue
            }
        }
    }

    public override class func canInit(with request: URLRequest) -> Bool {
        guard DebugPanelSDK.isNetworkLoggingEnabled else {
            return false
        }

        guard URLProtocol.property(forKey: handledKey, in: request) == nil else {
            return false
        }

        guard let scheme = request.url?.scheme?.lowercased() else {
            return false
        }

        return scheme == "http" || scheme == "https"
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    public override func startLoading() {
        let startedAt = Date()
        startDate = startedAt

        let sourceRequest = task?.originalRequest ?? request
        let forwardedRequest = Self.forwardedRequest(from: sourceRequest)
        loggedRequest = forwardedRequest
        let configuration = Self.forwardingConfigurationProvider()
        let session = URLSession(configuration: configuration)
        forwardingSession = session

        dataTask = session.dataTask(with: forwardedRequest) { [weak self] data, response, error in
            guard let self else {
                return
            }

            self.completeLoading(data: data, response: response, error: error, startedAt: startedAt)
        }

        dataTask?.resume()
    }

    public override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
        forwardingSession?.invalidateAndCancel()
        forwardingSession = nil
    }

    private static func forwardedRequest(from request: URLRequest) -> URLRequest {
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: handledKey, in: mutableRequest)

        if mutableRequest.httpBody == nil, let stream = mutableRequest.httpBodyStream {
            mutableRequest.httpBody = data(from: stream)
            mutableRequest.httpBodyStream = nil
        }

        return mutableRequest as URLRequest
    }

    private static func data(from stream: InputStream) -> Data {
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)

        stream.open()
        defer { stream.close() }

        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            data.append(buffer, count: count)
        }

        return data
    }

    private func completeLoading(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        startedAt: Date
    ) {
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data, data.isEmpty == false {
            client?.urlProtocol(self, didLoad: data)
        }

        let httpResponse = response as? HTTPURLResponse
        let recorder = DebugNetworkLogRecorder()
        recorder.record(
            request: loggedRequest ?? request,
            response: httpResponse,
            data: data,
            error: error,
            startDate: startedAt
        )

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }

        forwardingSession?.finishTasksAndInvalidate()
        forwardingSession = nil
    }

    static func resetForTesting() {
        forwardingConfigurationProvider = { .default }
    }

    private final class ForwardingState: @unchecked Sendable {
        let lock = NSLock()
        var provider: @Sendable () -> URLSessionConfiguration = { .default }
    }
}
