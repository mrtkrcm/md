//
//  InspectorMetadataView.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Inspector Metadata View

/// Native inspector panel for document metadata using modern SwiftUI.
/// Provides a sidebar view of YAML frontmatter with rich type detection
/// and formatting for dates, URLs, lists, and boolean values.
struct InspectorMetadataView: View {
    let frontmatter: Frontmatter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
                headerView

                Divider()

                // Content
                if frontmatter.entries.isEmpty {
                    rawYAMLView
                } else {
                    structuredMetadataView
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Label("Document Metadata", systemImage: "tag")
                .font(.system(
                    size: DesignTokens.Typography.bodySmall,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)

            Spacer()

            Text("YAML")
                .font(.system(
                    size: DesignTokens.Typography.caption,
                    weight: .medium,
                    design: .rounded
                ))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Color.secondary.opacity(DesignTokens.Opacity.light),
                    in: Capsule()
                )
        }
        .padding(.bottom, DesignTokens.Spacing.standard)
    }

    private var rawYAMLView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            Text("Raw Frontmatter")
                .font(.system(
                    size: DesignTokens.Typography.small,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)

            Text(frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                        .fill(Color.secondary.opacity(DesignTokens.Opacity.light))
                )
                .textSelection(.enabled)
        }
    }

    private var structuredMetadataView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.relaxed) {
            ForEach(Array(frontmatter.entries.enumerated()), id: \.offset) { _, entry in
                InspectorMetadataEntryView(entry: entry)
            }
        }
    }
}

// MARK: - Inspector Metadata Entry View

/// Single metadata entry row for the inspector panel.
/// Supports rich rendering based on value type (URL, date, list, boolean, number).
private struct InspectorMetadataEntryView: View {
    let entry: Frontmatter.Entry
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tight) {
            // Key label
            Text(entry.displayKey)
                .font(.system(
                    size: DesignTokens.Typography.caption,
                    weight: .semibold
                ))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)

            // Value with type-specific rendering
            valueView
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignTokens.Spacing.comfortable)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(Color.secondary.opacity(DesignTokens.Opacity.light))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .stroke(Color.secondary.opacity(isHovering ? 0.2 : 0), lineWidth: 1)
        )
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Copy Value") {
                copyToClipboard(entry.displayValue)
            }
            Button("Copy Key") {
                copyToClipboard(entry.key)
            }
            Divider()
            Button("Copy as YAML") {
                copyToClipboard("\(entry.key): \(entry.rawValue)")
            }
        }
    }

    @ViewBuilder
    private var valueView: some View {
        switch entry.typedValue {
        case .url(let url):
            Link(destination: url) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text(url.host ?? url.absoluteString)
                        .lineLimit(1)
                }
                .foregroundStyle(Color.accentColor)
            }
            .help("Open \(url.absoluteString)")

        case .date(let date):
            HStack(spacing: 4) {
                Text(formattedDate(date))
                Text("(")
                    .foregroundStyle(.secondary)
                Text(relativeTime(from: date))
                    .foregroundStyle(.secondary)
                Text(")")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: DesignTokens.Typography.standard))
            .foregroundStyle(.primary)
            .textSelection(.enabled)

        case .list(let items):
            FlowLayout(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: DesignTokens.Typography.small))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                        .foregroundStyle(.primary)
                }
            }

        case .boolean(let value):
            HStack(spacing: 4) {
                Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(value ? .green : .red)
                Text(value ? "Yes" : "No")
            }
            .font(.system(size: DesignTokens.Typography.standard))

        case .number(let number):
            Text(formattedNumber(number))
                .font(.system(size: DesignTokens.Typography.standard, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)

        case .text(let text):
            Text(text.isEmpty ? "\u{2014}" : text)
                .font(.system(size: DesignTokens.Typography.standard))
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formattedNumber(_ number: Double) -> String {
        if number == floor(number) {
            return String(format: "%.0f", number)
        }
        // Remove trailing zeros
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }

    private func copyToClipboard(_ string: String) {
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing grid, wrapping to the next line when needed.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing

                self.size.width = max(self.size.width, x)
            }

            size.height = y + rowHeight
        }
    }
}

// MARK: - Convenience Initializer

extension InspectorMetadataView {
    init?(frontmatter: Frontmatter?) {
        guard
            let frontmatter,
            !frontmatter.rawYAML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        self.frontmatter = frontmatter
    }
}

// MARK: - Previews

#Preview("Metadata Inspector") {
    InspectorMetadataView(frontmatter: Frontmatter(
        rawYAML: """
        title: Sample Document
        author: John Doe
        date: 2024-01-15
        tags: [swift, markdown, macos]
        published: true
        views: 1234
        """,
        entries: [],
        metadata: [:]
    ))
}

#Preview("Metadata Inspector - Empty") {
    InspectorMetadataView(frontmatter: Frontmatter(rawYAML: "", entries: [], metadata: [:]))
}
