import Foundation

public struct DebugLogFilter: Equatable, Sendable {
    public var query: String
    public var kind: DebugLogEntry.Kind?
    public var level: DebugLogEntry.Level?

    public init(
        query: String = "",
        kind: DebugLogEntry.Kind? = nil,
        level: DebugLogEntry.Level? = nil
    ) {
        self.query = query
        self.kind = kind
        self.level = level
    }

    public func matches(_ entry: DebugLogEntry) -> Bool {
        if let kind, entry.kind != kind {
            return false
        }

        if let level, entry.level != level {
            return false
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            return true
        }

        return entry.searchableText.localizedCaseInsensitiveContains(trimmedQuery)
    }
}

public enum DebugLogListDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case fullURL
    case hostAndPath
    case pathAndQuery
    case route

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fullURL:
            "Full URL"
        case .hostAndPath:
            "Host + Path"
        case .pathAndQuery:
            "Path + Query"
        case .route:
            "Route"
        }
    }
}

public extension DebugLogEntry {
    func listMessage(displayMode: DebugLogListDisplayMode) -> String {
        guard kind == .network, let url = networkURL else {
            return message
        }

        switch displayMode {
        case .fullURL:
            return url.absoluteString
        case .hostAndPath:
            let host = url.host(percentEncoded: false) ?? url.host() ?? ""
            return host.isEmpty ? routePath(from: url) : "\(host)\(routePath(from: url))"
        case .pathAndQuery:
            var value = routePath(from: url)
            if let query = url.query(percentEncoded: false), query.isEmpty == false {
                value += "?\(query)"
            }
            return value
        case .route:
            return routePath(from: url)
        }
    }

    fileprivate var searchableText: String {
        var values = [
            kind.rawValue,
            level.rawValue,
            title,
            message,
        ]

        for (key, value) in details {
            values.append(key)
            values.append(value)
        }

        return values.joined(separator: "\n")
    }

    private var networkURL: URL? {
        if let urlString = details["URL"], let url = URL(string: urlString) {
            return url
        }
        return URL(string: message)
    }

    private func routePath(from url: URL) -> String {
        let path = url.path(percentEncoded: false)
        return path.isEmpty ? "/" : path
    }
}
