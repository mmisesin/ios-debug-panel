import Foundation

public enum DebugPanelSDK {
    private static let state = State()

    public static var automaticNetworkLoggingEnabled: Bool {
        get {
            state.lock.withLock { state.isAutomaticNetworkLoggingEnabled }
        }
        set {
            let registrationChange = state.lock.withLock {
                state.isAutomaticNetworkLoggingEnabled = newValue
                if newValue, state.isBestEffortProtocolRegistered == false {
                    state.isBestEffortProtocolRegistered = true
                    return RegistrationChange.register
                } else if newValue == false, state.isBestEffortProtocolRegistered {
                    state.isBestEffortProtocolRegistered = false
                    return RegistrationChange.unregister
                }
                return RegistrationChange.none
            }

            switch registrationChange {
            case .register:
                URLProtocol.registerClass(DebugNetworkLoggingURLProtocol.self)
            case .unregister:
                URLProtocol.unregisterClass(DebugNetworkLoggingURLProtocol.self)
            case .none:
                break
            }
        }
    }

    public static var networkLoggingOptions: DebugNetworkLoggingOptions {
        get {
            state.lock.withLock { state.currentNetworkLoggingOptions }
        }
        set {
            state.lock.withLock {
                state.currentNetworkLoggingOptions = newValue
            }
        }
    }

    public static func instrument(_ configuration: URLSessionConfiguration) -> URLSessionConfiguration {
        guard configuration.identifier == nil else {
            return configuration
        }

        let protocolClass: AnyClass = DebugNetworkLoggingURLProtocol.self
        let existingProtocolClasses = configuration.protocolClasses ?? []
        if existingProtocolClasses.contains(where: { $0 == protocolClass }) {
            return configuration
        }

        configuration.protocolClasses = [protocolClass] + existingProtocolClasses
        return configuration
    }

    static var isNetworkLoggingEnabled: Bool {
        state.lock.withLock { state.isAutomaticNetworkLoggingEnabled }
    }

    static var activeNetworkLoggingOptions: DebugNetworkLoggingOptions {
        state.lock.withLock { state.currentNetworkLoggingOptions }
    }

    static var isBestEffortRegisteredForTesting: Bool {
        state.lock.withLock { state.isBestEffortProtocolRegistered }
    }

    static func resetForTesting() {
        state.lock.withLock {
            state.isAutomaticNetworkLoggingEnabled = false
            state.currentNetworkLoggingOptions = .metadataOnly
            state.isBestEffortProtocolRegistered = false
        }
    }

    private enum RegistrationChange {
        case none
        case register
        case unregister
    }

    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var isAutomaticNetworkLoggingEnabled = false
        var currentNetworkLoggingOptions = DebugNetworkLoggingOptions.metadataOnly
        var isBestEffortProtocolRegistered = false
    }
}
