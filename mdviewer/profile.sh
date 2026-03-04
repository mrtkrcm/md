#!/bin/bash
# Profile script for mdviewer performance analysis

set -e

echo "Building release version..."
cd "$(dirname "$0")"
just build

echo ""
echo "Creating test documents..."
mkdir -p /tmp/mdviewer-profile

# Small test
cat > /tmp/mdviewer-profile/small.md << 'EOF'
# Small Document
Simple paragraph with **bold** and *italic* text.

## List
- Item 1
- Item 2
- Item 3

## Code
```swift
let x = 42
```
EOF

# Medium test  
cat > /tmp/mdviewer-profile/medium.md << 'EOF'
# Medium Document

Lorem ipsum dolor sit amet, consectetur adipiscing elit.

## Section 1
- Item 1 with **bold**
- Item 2 with *italic*
- Item 3 with `code`

## Section 2
1. First
2. Second
3. Third

## Code Block
```swift
func fibonacci(_ n: Int) -> Int {
    if n <= 1 { return n }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

// More code here
let result = fibonacci(10)
print(result)
```

## Table
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

> Blockquote with **bold** text.
EOF

# Large test with many elements
cat > /tmp/mdviewer-profile/large.md << 'EOF'
# Large Performance Test Document

EOF

# Generate large content
for i in {1..50}; do
cat >> /tmp/mdviewer-profile/large.md << EOF

## Section $i

This is paragraph $i with **bold**, *italic*, and `code` text.

### Subsection $i.1
- Item ${i}.1
- Item ${i}.2
- Item ${i}.3

### Subsection $i.2
1. Ordered ${i}.1
2. Ordered ${i}.2

### Code Block $i
\`\`\`swift
func example$i() -> Int {
    let x = $i
    let y = x * 2
    return y + 10
}
\`\`\`

> Blockquote $i with **emphasis**.

EOF
done

echo ""
echo "Test documents created:"
ls -lh /tmp/mdviewer-profile/

echo ""
echo "Launching Instruments..."
echo "1. Select 'Points of Interest' template"
echo "2. Target: mdviewer process"
echo "3. Open test files in sequence:"
echo "   /tmp/mdviewer-profile/small.md"
echo "   /tmp/mdviewer-profile/medium.md"  
echo "   /tmp/mdviewer-profile/large.md"
echo ""

# Launch Instruments with Points of Interest template
open -a Instruments "$(dirname "$0")/.build/debug/mdviewer" 2>/dev/null || {
    echo "Instruments launch failed. Manual steps:"
    echo "1. Build: just build"
    echo "2. Launch Instruments from Xcode: Cmd+I"
    echo "3. Choose 'Points of Interest' template"
}
