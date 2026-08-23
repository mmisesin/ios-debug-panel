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

To make captured JSON bodies and header blocks easier to scan, opt in to beautified formatting:

```swift
DebugPanelView(formattingOptions: .beautified)
```

Beautified formatting pretty-prints JSON and normalizes header whitespace and ordering without changing the captured log entry. You can enable the behaviors separately:

```swift
DebugPanelView(
    formattingOptions: DebugLogFormattingOptions(
        prettyPrintsJSON: true,
        normalizesHeaders: false
    )
)
```

The default is `.raw`, which preserves the existing presentation. The **Copy Summary** action uses the same formatting options as the detail view.

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

## Automatic Network Logging

Enable best-effort URLSession logging at app launch:

```swift
DebugPanelSDK.automaticNetworkLoggingEnabled = true
DebugPanelSDK.networkLoggingOptions = .metadataOnly
```

For custom `URLSession` instances, instrument the configuration before creating the session:

```swift
let configuration = DebugPanelSDK.instrument(URLSessionConfiguration.default)
let session = URLSession(configuration: configuration)
```

Automatic logging records method, URL, status, duration, and redacted headers by default. Bodies are disabled by default:

```swift
DebugPanelSDK.networkLoggingOptions = DebugNetworkLoggingOptions(
    capturesHeaders: true,
    capturesBodies: true,
    maxBodyBytes: 32_768,
    redactedHeaders: ["Authorization", "Cookie", "Set-Cookie"]
)
```

`URLProtocol`-based logging cannot change sessions that were already created and does not support background sessions. Response bodies are capturable when body capture is enabled. Request bodies are only captured when Foundation exposes them to the interceptor; some `URLSession` upload paths hide request bodies from `URLProtocol`.

For Alamofire, add the `DebugPanelAlamofire` product and attach the event monitor to a custom session:

```swift
import Alamofire
import DebugPanelAlamofire

let session = Session(
    eventMonitors: [DebugPanelAlamofireEventMonitor()]
)
```

Alamofire's shared `Session.default` / `AF.request` singleton cannot be modified retroactively, so deterministic Alamofire logging requires a custom `Session`.

Entries are kept in memory for the current app session. Call `DebugLogger.shared.clear()` to remove them.

In the panel detail view, use **Copy Summary** to copy a readable summary of the selected log. Network summaries include request, status, duration, headers, bodies, response, and error details when they were recorded.

Use the panel search field and **Filters** menu to narrow logs by query, type, and level. Use the **View** menu to choose how network rows are displayed: full URL, host plus path, path plus query, or route only.

Inside a log detail view, use **Search this log** to find text in summary fields, headers, request payloads, response payloads, and other recorded details. The panel scrolls to the first matching field and highlights matching text.
