import Foundation

struct SampleData {
    static let content = """
    # Markdown Viewer Demo

    Welcome to **Markdown Viewer**! This is a simple app built with SwiftUI and `MarkdownUI`.

    ## Features

    - **Syntax Highlighting**: Code blocks are automatically highlighted.
    - **Themes**: Switch between different themes.
    - **Markdown Support**: Headers, lists, quotes, and more.

    ## Code Example

    Here is a snippet of Swift code:

    ```swift
    import SwiftUI

    struct ContentView: View {
        var body: some View {
            Text("Hello, World!")
                .padding()
        }
    }
    ```

    And some Python code:

    ```python
    def hello():
        print("Hello, World!")

    if __name__ == "__main__":
        hello()
    ```

    ## Quotes

    > "The best way to predict the future is to invent it."
    > — Alan Kay

    ## Lists

    1. First item
    2. Second item
       - Sub item
       - Another sub item
    3. Third item

    """
}
