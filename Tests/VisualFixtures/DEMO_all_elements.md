---
title: "Markdown Rendering Demo — All Elements"
author: "mdviewer test suite"
date: 2025-06-15
tags: [demo, test, rendering, comprehensive]
category: testing
version: 2.0
---

# Markdown Rendering Demo

This document exercises **every supported markdown element** to verify rendering fidelity, spacing stability, and scroll performance.

---

## Inline Formatting

Regular text with **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `inline code`.

Mixed: **bold with *nested italic* inside**, and *italic with **nested bold** inside*.

## Links and Images

- [External link](https://example.com)
- [Link with title](https://example.com "Example Site")
- Auto-linked URL: https://example.com
- Email: user@example.com

![Alt text for image](https://via.placeholder.com/600x200 "Placeholder image")

## Headings (All Levels)

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

## Paragraphs and Line Breaks

This is the first paragraph. It contains multiple sentences to test text wrapping and line height consistency across different font sizes and column widths. The paragraph should flow naturally without any jarring spacing.

This is the second paragraph. There should be consistent spacing between paragraphs — not too tight, not too loose. The block separator injector handles this.

This line has a  
hard line break (two trailing spaces).

## Block Quotes

> Single-level blockquote with enough text to wrap across multiple lines in most column widths.

> Multi-level blockquote:
>
> > Nested once — should show increased indentation.
> >
> > > Nested twice — even deeper indentation.

> **Blockquote with formatting**: *italic*, `code`, and [links](https://example.com).

## Ordered Lists

1. First item
2. Second item with enough text to potentially wrap to a second line depending on column width
3. Third item
   1. Nested ordered item A
   2. Nested ordered item B
      1. Deeply nested item
4. Fourth item

## Unordered Lists

- Item one
- Item two with longer text that might wrap
- Item three
  - Nested item alpha
  - Nested item beta
    - Deeply nested item
- Item four

## Task Lists

- [x] Completed task
- [ ] Incomplete task
- [x] Another completed task
  - [ ] Nested incomplete subtask
  - [x] Nested completed subtask

## Code Blocks

### Swift

```swift
import Foundation

@MainActor
final class PerformanceOptimizer {
    private var cache: [String: Any] = [:]
    private let lock = NSLock()

    func optimize(_ input: String) async throws -> Result<Data, Error> {
        // Check cache first
        if let cached = cache[input] as? Data {
            return .success(cached)
        }

        // Process asynchronously
        let result = try await Task.detached(priority: .utility) {
            let data = input.data(using: .utf8)!
            return data
        }.value

        cache[input] = result
        return .success(result)
    }
}
```

### Python

```python
from dataclasses import dataclass
from typing import Optional
import asyncio

@dataclass
class RenderConfig:
    """Configuration for the markdown render pipeline."""
    theme: str = "default"
    font_size: float = 14.0
    line_spacing: float = 1.5
    max_width: Optional[int] = 720

async def render_document(content: str, config: RenderConfig) -> str:
    """Render markdown content with the given configuration."""
    await asyncio.sleep(0.01)  # Simulate async work
    return f"<rendered>{content}</rendered>"

if __name__ == "__main__":
    config = RenderConfig(theme="dark", font_size=16.0)
    result = asyncio.run(render_document("# Hello", config))
    print(result)
```

### TypeScript

```typescript
interface ScrollMetrics {
  offset: number;
  contentHeight: number;
  visibleHeight: number;
  velocity: number;
}

class ScrollPerformanceTracker {
  private metrics: ScrollMetrics[] = [];
  private frameCount = 0;

  track(metrics: ScrollMetrics): void {
    this.metrics.push(metrics);
    this.frameCount++;

    if (this.frameCount % 120 === 0) {
      this.reportFPS();
    }
  }

  private reportFPS(): void {
    const avgVelocity = this.metrics.reduce((sum, m) => sum + m.velocity, 0) / this.metrics.length;
    console.log(`Avg scroll velocity: ${avgVelocity.toFixed(2)}px/frame`);
  }
}
```

### Bash

```bash
#!/bin/bash
set -euo pipefail

# Build and test the application
echo "Building mdviewer..."
swift build 2>&1 | tail -5

echo "Running tests..."
swift test --parallel 2>&1 | grep -E "(Test Suite|Executed)"

echo "Done!"
```

### JSON

```json
{
  "name": "mdviewer",
  "version": "1.0.0",
  "settings": {
    "theme": "auto",
    "fontSize": 14,
    "columnWidth": 720,
    "showLineNumbers": true,
    "syntaxHighlighting": {
      "enabled": true,
      "palette": "midnight"
    }
  }
}
```

### Plain (no language)

```
This is a plain code block without language specification.
It should render in a monospace font without syntax highlighting.
    Indented lines should preserve their whitespace.
```

## Tables

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| CATransaction wrapping | Done | High | Suppresses implicit CA animations |
| Async heading cache | Done | High | Task.detached(priority: .utility) |
| Debounced parsing | Done | Medium | 150ms on keystroke |
| Path cache | Done | High | NSLock-based thread-safe cache |
| Static cell heights | Done | Critical | Eliminates CoreText queries |

### Wide Table

| Column A | Column B | Column C | Column D | Column E | Column F | Column G |
|----------|----------|----------|----------|----------|----------|----------|
| Data 1 | Data 2 | Data 3 | Data 4 | Data 5 | Data 6 | Data 7 |
| Longer content here | Short | Medium length | X | Another cell | Testing | Final |

## Horizontal Rules

Above the rule.

---

Between rules.

***

Below the rules.

- ## HTML Entities and Special Characters

- Em dash: —
- En dash: –
- Ellipsis: …
- Copyright: ©
- Trademark: ™
- Arrows: → ← ↑ ↓
- Math: ± × ÷ ≠ ≤ ≥
- Quotes: "smart" and 'single'
- Ampersand: &

## Long Paragraph (Stress Test)

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.

## Deeply Nested Structure

- Level 1
  - Level 2
    - Level 3
      - Level 4 with **bold** and `code`
        - Level 5 — this is quite deep
  - Back to level 2
- Back to level 1

1. Ordered level 1
   1. Ordered level 2
      1. Ordered level 3
         - Mixed: unordered inside ordered
         - Another mixed item

## Footnote-Style References

This text references something important[^1] and something else[^2].

[^1]: First footnote with detailed explanation.  
[^2]: Second footnote with a [link](https://example.com).

## Definition-Style Content

Term 1
: Definition for term 1, which may span multiple lines if the content is long enough to wrap.

Term 2
: Definition for term 2.
: Alternative definition for term 2.

## Emoji and Unicode

Emoji: 🚀 🎯 ✅ ❌ ⚡ 🔥 💡 🐛 🔧 📦

Unicode blocks: ░▒▓█ ╔═══╗ │ Box │ ╚═══╝

CJK: 日本語テスト 中文测试 한국어 테스트

## Adjacent Code Blocks (Spacing Test)

```swift
let a = 1
```

```python
b = 2
```

```bash
c=3
```

## Mixed Content Stress Test

Here is a paragraph immediately before a list:
- Item right after paragraph
- Another item

And a paragraph immediately after the list continues here. Then a blockquote:

> Quote right after paragraph

Followed by a code block:

```swift
// Code right after blockquote
let x = 42
```

Then a table:

| A | B |
|---|---|
| 1 | 2 |

And finally, a heading:

### Heading After Table

This tests that spacing between all different block types remains consistent and visually balanced.

---

*End of rendering demo — if you can read this without layout glitches, the render pipeline is working correctly.*
