# Vertical Rhythm Fixture

This paragraph sits between headings and verifies baseline paragraph rhythm.

## List and Quote Rhythm

Spacing before this paragraph confirms heading-to-paragraph transitions stay readable.

- A first bullet item with realistic text length for rhythm tests.
- A second bullet item with enough width to force normal wrapping behavior.

1. A numbered item with ordered-list spacing expectations.
2. Another numbered item to keep numbering continuity.

> A compact quote keeps transitions soft.
> It should preserve paragraph rhythm without crowding.

```swift
let rhythm = true
let styles = ["heading", "list", "table", "rule"]
```

---

### Table and Divider Rhythm

| Mode | Status |
| --- | --- |
| compact | tuned |
| relaxed | stable |

Spacing before this paragraph validates table-to-paragraph separation after row groups.
Spacing after table should remain intentional.

#### Nested Heading Hierarchy

This paragraph tests the transition from H4 to body text.

##### Fifth Level Heading

Content after H5 should maintain readable spacing without excessive gaps.

###### Sixth Level Heading

The smallest heading level should still have appropriate vertical rhythm.

Final paragraph in the nested heading section.

## Deep Nesting Section

> First level quote introduces the nesting test.
>
> > Second level quote adds indentation depth.
> >
> > > Third level quote tests maximum nesting rhythm.

Paragraph after nested quotes validates spacing recovery.

- Top level list item
  - Nested list item at level two
    - Deep nested item at level three
  - Back to level two
- Return to top level

Paragraph following nested list structure.

### Mixed Nesting Block

> Quote containing a list:
> - Item inside quote
> - Another item
>
> > Nested quote with code:
> > ```
> > nested code block
> > ```

Final paragraph validates exit from complex nesting.
