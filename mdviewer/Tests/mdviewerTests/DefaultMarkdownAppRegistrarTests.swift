//
//  DefaultMarkdownAppRegistrarTests.swift
//  mdviewer
//

#if canImport(XCTest)
    #if os(macOS)
        @testable internal import mdviewer
        internal import XCTest

        @MainActor
        final class DefaultMarkdownAppRegistrarTests: XCTestCase {
            private let contentTypeIdentifiers = [
                "net.daringfireball.markdown",
                "com.unknown.md",
                "dyn.markdown",
                "dyn.mdown",
                "dyn.mkd",
                "dyn.mkdn",
            ]

            func testRegistersCanonicalAndExtensionResolvedMarkdownContentTypes() throws {
                var contentTypeRegistrations: [(String, LSRolesMask, String)] = []

                let client = DefaultMarkdownAppRegistrar.LaunchServicesClient(
                    setDefaultRoleHandlerForContentType: { contentType, role, bundleIdentifier in
                        contentTypeRegistrations.append((contentType as String, role, bundleIdentifier as String))
                        return noErr
                    },
                    copyDefaultRoleHandlerForContentType: { _, _ in
                        "com.example.mdviewer"
                    }
                )

                try DefaultMarkdownAppRegistrar.setAppAsDefaultMarkdownHandler(
                    bundleIdentifier: "com.example.mdviewer",
                    client: client,
                    contentTypeIdentifiers: contentTypeIdentifiers
                )

                XCTAssertEqual(contentTypeRegistrations.count, contentTypeIdentifiers.count)
                XCTAssertEqual(contentTypeRegistrations.map(\.0), contentTypeIdentifiers)
                XCTAssertTrue(contentTypeRegistrations.allSatisfy { $0.1 == .all })
                XCTAssertTrue(contentTypeRegistrations.allSatisfy { $0.2 == "com.example.mdviewer" })
            }

            func testThrowsWhenMdContentTypeRegistrationFails() {
                let client = DefaultMarkdownAppRegistrar.LaunchServicesClient(
                    setDefaultRoleHandlerForContentType: { contentType, _, _ in
                        contentType as String == "com.unknown.md" ? OSStatus(-50) : noErr
                    },
                    copyDefaultRoleHandlerForContentType: { _, _ in
                        "com.example.mdviewer"
                    }
                )

                XCTAssertThrowsError(
                    try DefaultMarkdownAppRegistrar.setAppAsDefaultMarkdownHandler(
                        bundleIdentifier: "com.example.mdviewer",
                        client: client,
                        contentTypeIdentifiers: contentTypeIdentifiers
                    )
                ) { error in
                    guard case let RegistrarError.launchServicesFailure(target, status) = error else {
                        return XCTFail("Unexpected error: \(error)")
                    }
                    XCTAssertEqual(target, "content type com.unknown.md")
                    XCTAssertEqual(status, -50)
                }
            }

            func testThrowsWhenLaunchServicesDoesNotPersistMdContentTypeHandler() {
                let client = DefaultMarkdownAppRegistrar.LaunchServicesClient(
                    setDefaultRoleHandlerForContentType: { _, _, _ in
                        noErr
                    },
                    copyDefaultRoleHandlerForContentType: { contentType, _ in
                        contentType as String == "com.unknown.md"
                            ? "info.iwaki.markdowneditor"
                            : "com.example.mdviewer"
                    }
                )

                XCTAssertThrowsError(
                    try DefaultMarkdownAppRegistrar.setAppAsDefaultMarkdownHandler(
                        bundleIdentifier: "com.example.mdviewer",
                        client: client,
                        contentTypeIdentifiers: contentTypeIdentifiers
                    )
                ) { error in
                    switch error {
                    case let RegistrarError.verificationFailed(
                        target,
                        expectedBundleIdentifier,
                        actualBundleIdentifier
                    ):
                        XCTAssertEqual(target, "content type com.unknown.md")
                        XCTAssertEqual(expectedBundleIdentifier, "com.example.mdviewer")
                        XCTAssertEqual(actualBundleIdentifier, "info.iwaki.markdowneditor")
                    default:
                        XCTFail("Unexpected error: \(error)")
                    }
                }
            }
        }
    #endif
#endif
