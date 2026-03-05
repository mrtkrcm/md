//
//  TableOfContentsView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Table of Contents View

/// Displays a navigable table of contents for the current document.
struct TableOfContentsView: View {
    let documentText: String
    let onSelectHeading: (Int) -> Void // Line number or character index

    @State private var headings: [Heading] = []
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if headings.isEmpty {
                    EmptyToCState()
                } else {
                    ForEach(headings) { heading in
                        HeadingRow(heading: heading) {
                            onSelectHeading(heading.lineIndex)
                        }
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.standard)
        }
        .task(id: documentText) {
            headings = await parseHeadings(from: documentText)
        }
    }

    // MARK: - Parsing

    struct Heading: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let level: Int
        let lineIndex: Int
    }

    private func parseHeadings(from text: String) async -> [Heading] {
        await Task.detached {
            var results: [Heading] = []
            let lines = text.components(separatedBy: .newlines)
            var inCodeBlock = false

            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Track code blocks to ignore headings inside them
                if trimmed.hasPrefix("```") {
                    inCodeBlock.toggle()
                    continue
                }
                if inCodeBlock { continue }

                if trimmed.hasPrefix("#") {
                    // Count hashes
                    var level = 0
                    for char in trimmed {
                        if char == "#" {
                            level += 1
                        } else {
                            break
                        }
                    }

                    // Validate level (1-6) and ensure space after hashes
                    if level >= 1, level <= 6 {
                        let contentIndex = line.index(line.startIndex, offsetBy: level)
                        if contentIndex < line.endIndex {
                            let suffix = line[contentIndex...]
                            if suffix.hasPrefix(" ") {
                                let headingText = suffix.trimmingCharacters(in: .whitespaces)
                                results.append(Heading(text: headingText, level: level, lineIndex: index))
                            }
                        }
                    }
                }
            }
            return results
        }.value
    }
}

// MARK: - Components

private struct HeadingRow: View {
    let heading: TableOfContentsView.Heading
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Indentation based on level
                Color.clear
                    .frame(width: CGFloat(heading.level - 1) * 12)

                Text(heading.text)
                    .font(.system(size: DesignTokens.Typography.standard))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(isHovered ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.wide)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
                .padding(.horizontal, DesignTokens.Spacing.standard)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(heading.text), level \(heading.level)")
        .accessibilityHint("Jump to this heading")
    }
}

private struct EmptyToCState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.relaxed) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No Headings")
                .font(.headline)
            Text("This document has no detected headings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.extraLarge)
        .frame(maxWidth: .infinity)
    }
}
