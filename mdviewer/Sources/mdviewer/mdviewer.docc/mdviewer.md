# ``mdviewer``

A modern, native Markdown viewer for macOS with a liquid design system.

## Overview

mdviewer is a fast, native macOS application for viewing Markdown files. It features:

- **Liquid Design System**: Fluid animations and glass panel effects
- **Native Performance**: Built with SwiftUI and AppKit for optimal performance
- **Syntax Highlighting**: Code block highlighting for multiple languages
- **Live Preview**: Real-time Markdown rendering
- **Type-Safe Preferences**: Robust preference system with `@AppStorage`

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>

### Rendering Pipeline

- <doc:RenderingPipeline>
- ``MarkdownRenderService``
- ``MarkdownParser``
- ``SyntaxHighlighter``

### UI Components

- ``ContentView``
- ``ReaderTextView``
- ``FloatingMetadataView``

### Theming

- ``DesignTokens``
- ``AppTheme``
- ``NativeThemePalette``

### Preferences

- ``StoredPreference``
- ``ReaderMode``
- ``AppearanceMode``
