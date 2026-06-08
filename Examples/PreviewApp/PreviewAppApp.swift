import SwiftUI

@main
struct PreviewAppApp: App {
    private let logger = PreviewLogFactory.makeLogger()

    var body: some Scene {
        WindowGroup {
            DebugPanelView(logger: logger)
        }
    }
}
