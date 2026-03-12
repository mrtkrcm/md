//
//  DefaultMarkdownAppRegistrar.swift
//  mdviewer
//

#if os(macOS)
    internal import CoreServices
    internal import Foundation
    internal import OSLog
    internal import UniformTypeIdentifiers

    @MainActor
    enum DefaultMarkdownAppRegistrar {
        private static let logger = Logger(subsystem: "mdviewer", category: "default-association")
        private static let canonicalMarkdownContentType = "net.daringfireball.markdown"
        private static let markdownFilenameExtensions = ["md", "markdown", "mdown", "mkd", "mkdn"]

        struct LaunchServicesClient {
            var setDefaultRoleHandlerForContentType: (CFString, LSRolesMask, CFString) -> OSStatus
            var copyDefaultRoleHandlerForContentType: (CFString, LSRolesMask) -> String?

            @MainActor
            static let live = Self(
                setDefaultRoleHandlerForContentType: { contentType, role, bundleIdentifier in
                    LSSetDefaultRoleHandlerForContentType(contentType, role, bundleIdentifier)
                },
                copyDefaultRoleHandlerForContentType: { contentType, role in
                    LSCopyDefaultRoleHandlerForContentType(contentType, role)?.takeRetainedValue() as String?
                }
            )
        }

        static func setAppAsDefaultMarkdownHandler(
            bundleIdentifier: String? = Bundle.main.bundleIdentifier,
            client: LaunchServicesClient = .live,
            contentTypeIdentifiers: [String]? = nil
        ) throws {
            guard let bundleIdentifier else {
                throw RegistrarError.missingBundleIdentifier
            }
            let contentTypeIdentifiers = contentTypeIdentifiers ?? markdownContentTypeIdentifiers()

            for contentTypeIdentifier in contentTypeIdentifiers {
                try setDefaultRoleHandler(
                    target: "content type \(contentTypeIdentifier)",
                    status: client.setDefaultRoleHandlerForContentType(
                        contentTypeIdentifier as CFString,
                        .all,
                        bundleIdentifier as CFString
                    )
                )
            }

            for contentTypeIdentifier in contentTypeIdentifiers {
                try verifyHandler(
                    target: "content type \(contentTypeIdentifier)",
                    actualBundleIdentifier: client.copyDefaultRoleHandlerForContentType(
                        contentTypeIdentifier as CFString,
                        .all
                    ),
                    expectedBundleIdentifier: bundleIdentifier
                )
            }

            logger.info("Set default markdown handler to bundle id: \(bundleIdentifier)")
        }

        private static func markdownContentTypeIdentifiers() -> [String] {
            var identifiers = [canonicalMarkdownContentType]

            for filenameExtension in markdownFilenameExtensions {
                guard let contentTypeIdentifier = UTType(filenameExtension: filenameExtension)?.identifier else {
                    continue
                }
                if !identifiers.contains(contentTypeIdentifier) {
                    identifiers.append(contentTypeIdentifier)
                }
            }

            return identifiers
        }

        private static func setDefaultRoleHandler(target: String, status: OSStatus) throws {
            guard status == noErr else {
                logger.error("LaunchServices failed for \(target, privacy: .public) with status: \(status)")
                throw RegistrarError.launchServicesFailure(target: target, status: status)
            }
        }

        private static func verifyHandler(
            target: String,
            actualBundleIdentifier: String?,
            expectedBundleIdentifier: String
        ) throws {
            guard actualBundleIdentifier == expectedBundleIdentifier else {
                logger.error(
                    "LaunchServices verification mismatch for \(target, privacy: .public). Expected \(expectedBundleIdentifier, privacy: .public), got \(actualBundleIdentifier ?? "nil", privacy: .public)"
                )
                throw RegistrarError.verificationFailed(
                    target: target,
                    expectedBundleIdentifier: expectedBundleIdentifier,
                    actualBundleIdentifier: actualBundleIdentifier
                )
            }
        }
    }

    enum RegistrarError: LocalizedError {
        case missingBundleIdentifier
        case launchServicesFailure(target: String, status: OSStatus)
        case verificationFailed(target: String, expectedBundleIdentifier: String, actualBundleIdentifier: String?)

        var errorDescription: String? {
            switch self {
            case .missingBundleIdentifier:
                return "App bundle identifier could not be resolved."
            case let .launchServicesFailure(target, status):
                return "LaunchServices returned status \(status) while updating \(target)."
            case let .verificationFailed(target, expectedBundleIdentifier, actualBundleIdentifier):
                let actualDescription = actualBundleIdentifier ?? "none"
                return "LaunchServices did not persist \(target) to \(expectedBundleIdentifier). Current handler: \(actualDescription)."
            }
        }
    }
#endif
