import Alamofire
import Foundation
@_spi(Internal) import DebugPanel

public final class DebugPanelAlamofireEventMonitor: EventMonitor, @unchecked Sendable {
    public let queue: DispatchQueue

    private let logger: DebugLogger
    private let lock = NSLock()
    private var startDates: [ObjectIdentifier: Date] = [:]
    private var recordedRequests: Set<ObjectIdentifier> = []

    public init(
        logger: DebugLogger = .shared,
        queue: DispatchQueue = DispatchQueue(label: "com.debugpanel.alamofire-event-monitor")
    ) {
        self.logger = logger
        self.queue = queue
    }

    public func requestDidResume(_ request: Request) {
        lock.withLock {
            startDates[ObjectIdentifier(request)] = Date()
        }
    }

    public func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: AFError?) {
        guard let error else {
            return
        }

        recordOnce(
            requestID: ObjectIdentifier(request),
            urlRequest: task.originalRequest ?? task.currentRequest,
            httpResponse: task.response as? HTTPURLResponse,
            data: nil,
            error: error
        )
    }

    public func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) where Value: Sendable {
        recordOnce(
            requestID: ObjectIdentifier(request),
            urlRequest: response.request,
            httpResponse: response.response,
            data: response.data,
            error: response.error
        )
    }

    func recordCompletedRequest(
        requestID: ObjectIdentifier? = nil,
        urlRequest: URLRequest?,
        httpResponse: HTTPURLResponse?,
        data: Data?,
        error: Error?,
        startDate: Date? = nil,
        endDate: Date = Date()
    ) {
        guard let urlRequest else {
            return
        }

        let startedAt: Date
        if let startDate {
            startedAt = startDate
        } else if let requestID {
            startedAt = lock.withLock { startDates[requestID] } ?? endDate
        } else {
            startedAt = endDate
        }

        DebugNetworkLogRecorder(
            logger: logger,
            options: DebugPanelSDK.networkLoggingOptions
        ).record(
            request: urlRequest,
            response: httpResponse,
            data: data,
            error: error,
            startDate: startedAt,
            endDate: endDate
        )
    }

    private func recordOnce(
        requestID: ObjectIdentifier,
        urlRequest: URLRequest?,
        httpResponse: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) {
        let shouldRecord = lock.withLock {
            if recordedRequests.contains(requestID) {
                return false
            }
            recordedRequests.insert(requestID)
            return true
        }

        guard shouldRecord else {
            return
        }

        recordCompletedRequest(
            requestID: requestID,
            urlRequest: urlRequest,
            httpResponse: httpResponse,
            data: data,
            error: error
        )
    }
}
