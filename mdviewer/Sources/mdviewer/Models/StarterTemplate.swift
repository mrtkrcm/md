internal import Foundation

enum StarterTemplate {
    static let markdown = """
    # Markdown Viewer

    ## Start here

    This document is your workspace.
    Open an existing Markdown file, or start editing right away.

    ## Quick actions

    - Use the toolbar to **Open...** a file from disk.
    - Switch appearance with the **Theme** picker.
    - Use **Reset Starter** any time to restore this template.

    ## Example

    ```swift
    import SwiftUI

    struct GreetingView: View {
        var body: some View {
            Text("Hello from Markdown Viewer")
        }
    }
    ```

    ## Formatting tips

    - `#` for headings
    - `-` for lists
    - Triple backticks for code blocks
    """
}
