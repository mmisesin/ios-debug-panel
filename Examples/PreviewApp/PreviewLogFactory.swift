import Foundation

enum PreviewLogFactory {
    static func makeLogger() -> DebugLogger {
        let logger = DebugLogger(maxEntryCount: 100)

        logger.recordConsole(
            "User opened the debug panel preview",
            level: .info,
            category: "Lifecycle",
            details: ["Screen": "DebugPanelView"]
        )

        logger.recordNetwork(
            method: "GET",
            url: URL(string: "https://api.example.com/v1/users/42/profile?include=teams,roles,permissions")!,
            statusCode: 200,
            duration: 0.184,
            requestHeaders: [
                "Accept": "application/json",
                "Authorization": "Bearer preview-token",
            ],
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: #"{"id":42,"name":"Preview User","teams":["iOS"]}"#
        )

        logger.recordNetwork(
            method: "POST",
            url: URL(string: "https://api.example.com/v1/sessions")!,
            statusCode: 201,
            duration: 0.096,
            requestBody: #"{"device":"iPhone 16 Pro"}"#,
            responseBody: #"{"token":"preview-session"}"#
        )

        logger.recordNetwork(
            method: "DELETE",
            url: URL(string: "https://api.example.com/v1/cache/expired-items?dryRun=true")!,
            statusCode: 404,
            duration: 0.052,
            responseBody: #"{"reason":"No expired cache entries found"}"#
        )

        logger.recordConsole(
            "Feature flag changed",
            level: .debug,
            category: "Flags",
            details: [
                "Key": "debug_panel_route_rows",
                "Value": "enabled",
            ]
        )

        return logger
    }
}
