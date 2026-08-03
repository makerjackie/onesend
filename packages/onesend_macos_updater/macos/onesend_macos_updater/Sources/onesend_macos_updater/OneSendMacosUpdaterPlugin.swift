import Cocoa
import FlutterMacOS
import Sparkle

/// Thin bridge around Sparkle's standard, sandbox-compatible update flow.
///
/// Feed URL, public key, scheduling defaults, and XPC behavior intentionally
/// live in the host application's Info.plist. Sparkle persists user changes in
/// its own defaults domain, so the Flutter layer does not duplicate them.
public final class OneSendMacosUpdaterPlugin: NSObject, FlutterPlugin {
    private let updaterController: SPUStandardUpdaterController

    public override init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.makerjackie.onesend/desktop_updater",
            binaryMessenger: registrar.messenger
        )
        let instance = OneSendMacosUpdaterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        dispatchPrecondition(condition: .onQueue(.main))

        switch call.method {
        case "checkForUpdates":
            guard updaterController.updater.canCheckForUpdates else {
                result(
                    FlutterError(
                        code: "check_in_progress",
                        message: "An update check is already in progress.",
                        details: nil
                    )
                )
                return
            }
            updaterController.checkForUpdates(nil)
            result(nil)

        case "getAutomaticChecksEnabled":
            result(updaterController.updater.automaticallyChecksForUpdates)

        case "setAutomaticChecksEnabled":
            guard
                let arguments = call.arguments as? [String: Any],
                let enabled = arguments["enabled"] as? Bool
            else {
                result(
                    FlutterError(
                        code: "invalid_arguments",
                        message: "The enabled boolean is required.",
                        details: nil
                    )
                )
                return
            }
            updaterController.updater.automaticallyChecksForUpdates = enabled
            if enabled {
                updaterController.updater.resetUpdateCycleAfterShortDelay()
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
