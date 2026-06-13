# DebugPanel

DebugPanel is a Swift Package for adding an in-app log viewer to iOS and macOS apps.

## Installation

Add this repository as a Swift Package dependency, then import `DebugPanel`.

## Presenting the Panel

```swift
import DebugPanel
import SwiftUI

struct DebugSheet: View {
    var body: some View {
        DebugPanelView()
    }
}
```

`DebugPanelView` reads from `DebugLogger.shared` by default. You can also pass a custom logger:

```swift
DebugPanelView(logger: DebugLogger(maxEntryCount: 1_000))
```

## Recording Console Logs

```swift
DebugLogger.shared.recordConsole(
    "Loaded profile",
    level: .debug,
    category: "Account"
)
```

## Recording Network Logs

```swift
DebugLogger.shared.recordNetwork(
    method: "GET",
    url: URL(string: "https://example.com/users")!,
    statusCode: 200,
    duration: 0.125,
    requestHeaders: ["Authorization": "Bearer token"],
    responseHeaders: ["Content-Type": "application/json"],
    responseBody: #"{"ok":true}"#
)
```

Entries are kept in memory for the current app session. Call `DebugLogger.shared.clear()` to remove them.

In the panel detail view, use **Copy Summary** to copy a readable summary of the selected log. Network summaries include request, status, duration, headers, bodies, response, and error details when they were recorded.

Use the panel search field and **Filters** menu to narrow logs by query, type, and level. Use the **View** menu to choose how network rows are displayed: full URL, host plus path, path plus query, or route only.

Inside a log detail view, use **Search this log** to find text in summary fields, headers, request payloads, response payloads, and other recorded details. The panel scrolls to the first matching field and highlights matching text.
