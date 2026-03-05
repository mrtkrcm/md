//
//  DefaultMarkdownAppRegistrar.swift
//  mdviewer
//

#if os(macOS)
    internal import CoreServices
    internal import Foundation
    internal import OSLog

    @MainActor
    enum DefaultMarkdownAppRegistrar {
        private static let logger = Logger(subsystem: "mdviewer", category: "default-association")
        private static let markdownContentType = "net.daringfireball.markdown" as CFString

        static func setAppAsDefaultMarkdownHandler() throws {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                throw RegistrarError.missingBundleIdentifier
            }

            let status = LSSetDefaultRoleHandlerForContentType(
                markdownContentType,
                .all,
                bundleIdentifier as CFString
            )

            guard status == noErr else {
                logger.error("LSSetDefaultRoleHandlerForContentType failed with status: \(status)")
                throw RegistrarError.launchServicesFailure(status: status)
            }

            logger.info("Set default markdown handler to bundle id: \(bundleIdentifier)")
        }
    }

    enum RegistrarError: LocalizedError {
        case missingBundleIdentifier
        case launchServicesFailure(status: OSStatus)

        var errorDescription: String? {
            switch self {
            case .missingBundleIdentifier:
                return "App bundle identifier could not be resolved."
            case let .launchServicesFailure(status):
                return "LaunchServices returned status \(status) while updating default file association."
            }
        }
    }
#endif
