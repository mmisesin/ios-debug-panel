import Foundation

public final class DebugLogger: @unchecked Sendable {
    public static let shared = DebugLogger()

    private let lock = NSLock()
    private var storedEntries: [DebugLogEntry]
    private var continuations: [UUID: AsyncStream<[DebugLogEntry]>.Continuation]

    public let maxEntryCount: Int

    public init(maxEntryCount: Int = 500) {
        self.maxEntryCount = max(1, maxEntryCount)
        self.storedEntries = []
        self.continuations = [:]
    }

    public var entries: [DebugLogEntry] {
        lock.withLock { storedEntries }
    }

    public func record(_ entry: DebugLogEntry) {
        let snapshot = lock.withLock {
            storedEntries.append(entry)
            if storedEntries.count > maxEntryCount {
                storedEntries.removeFirst(storedEntries.count - maxEntryCount)
            }
            return storedEntries
        }
        yield(snapshot)
    }

    public func recordConsole(
        _ message: String,
        level: DebugLogEntry.Level = .info,
        category: String? = nil,
        details: [String: String] = [:],
        date: Date = Date()
    ) {
        var entryDetails = details
        if let category {
            entryDetails["Category"] = category
        }

        record(
            DebugLogEntry(
                date: date,
                kind: .console,
                level: level,
                title: category ?? "Console",
                message: message,
                details: entryDetails
            )
        )
    }

    public func recordNetwork(
        method: String,
        url: URL,
        statusCode: Int? = nil,
        duration: TimeInterval? = nil,
        requestHeaders: [String: String] = [:],
        responseHeaders: [String: String] = [:],
        requestBody: String? = nil,
        responseBody: String? = nil,
        error: Error? = nil,
        date: Date = Date()
    ) {
        var details: [String: String] = [
            "Method": method.uppercased(),
            "URL": url.absoluteString,
        ]

        if let statusCode {
            details["Status"] = String(statusCode)
        }

        if let duration {
            details["Duration"] = String(format: "%.0f ms", duration * 1000)
        }

        if !requestHeaders.isEmpty {
            details["Request Headers"] = formattedHeaders(requestHeaders)
        }

        if !responseHeaders.isEmpty {
            details["Response Headers"] = formattedHeaders(responseHeaders)
        }

        if let requestBody, !requestBody.isEmpty {
            details["Request Body"] = requestBody
        }

        if let responseBody, !responseBody.isEmpty {
            details["Response Body"] = responseBody
        }

        if let error {
            details["Error"] = error.localizedDescription
        }

        let level: DebugLogEntry.Level
        if error != nil {
            level = .error
        } else if let statusCode, statusCode >= 400 {
            level = .warning
        } else {
            level = .info
        }

        let title = [method.uppercased(), statusCode.map(String.init)]
            .compactMap { $0 }
            .joined(separator: " ")

        record(
            DebugLogEntry(
                date: date,
                kind: .network,
                level: level,
                title: title,
                message: url.absoluteString,
                details: details
            )
        )
    }

    public func clear() {
        let snapshot = lock.withLock {
            storedEntries.removeAll()
            return storedEntries
        }
        yield(snapshot)
    }

    public func snapshots() -> AsyncStream<[DebugLogEntry]> {
        AsyncStream { continuation in
            let id = UUID()
            let snapshot = lock.withLock {
                continuations[id] = continuation
                return storedEntries
            }

            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.continuations[id] = nil
                }
            }
        }
    }

    private func yield(_ snapshot: [DebugLogEntry]) {
        let activeContinuations = lock.withLock {
            Array(continuations.values)
        }

        for continuation in activeContinuations {
            continuation.yield(snapshot)
        }
    }

    private func formattedHeaders(_ headers: [String: String]) -> String {
        headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
}
