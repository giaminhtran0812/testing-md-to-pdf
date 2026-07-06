---
title: "Standard Product Test Document"
product: "Aptara MCS"
doc_number: "AAA693120-TEST"
revision: "A"
author: "Codex"
date: "2026-07-07"
copyright_year: "2026"
confidentiality: "Baker Hughes Confidential"
---

# Document Overview

This sample document is designed to exercise the Pandoc template and Lua style
filter. It includes headings, paragraphs, emphasis, links, block quotes, lists,
figures, standard tables, custom-width tables, code blocks, and a landscape
section.

The text also includes **bold text**, *italic text*, `inline code`, and a link
to [Baker Hughes](https://www.bakerhughes.com).

## Purpose

The purpose of this file is to provide a repeatable conversion input for PDF
style testing. The generated PDF should show the front page, table of contents,
running header, footer, page numbers, table captions, figure captions, and
section-based numbering.

### Scope

This section confirms that third-level headings render with the expected
spacing and typography.

> This is a block quote. It should remain readable and should not collide with
> surrounding body text or section headings.

# Lists

## Bullet Lists

- First-level bullet item.
- Another first-level bullet item with a longer sentence to check wrapping and
  left alignment.
  - Second-level bullet item.
  - Another second-level bullet item.
    - Third-level bullet item.
    - Another third-level bullet item.

## Numbered Lists

1. First numbered item with enough text to wrap onto a second line in the PDF.
2. Second numbered item.
   1. Nested numbered item.
   2. Second nested numbered item.
      1. Third-level numbered item.
      2. Another third-level numbered item.

# Figures

![Baker Hughes logo test image](Pandoc/logo.png){width=35%}

The figure above checks image placement, caption styling, and section-based
figure numbering.

![Random photo test image](randomphoto.jpg){width=45%}

The second figure checks a local image that sits beside this Markdown source
file.

# Tables

Table: Standard two-column table

| Field | Value |
|---|---|
| Product | Aptara MCS |
| Document Number | AAA693120-TEST |
| Revision | A |
| Owner | Engineering Documentation |

Table: Standard three-column table

| Step | Owner | Description |
|---|---|---|
| 1 | Engineering | Prepare source Markdown and metadata. |
| 2 | Documentation | Convert Markdown to PDF using the Pandoc template. |
| 3 | Review | Check front page, TOC, headers, footers, and tables. |

::: {.table-cols width="0.15,0.30,0.55"}
Table: Custom-width table using the style filter

| ID | Area | Verification |
|---|---|---|
| T-01 | Header | Product, title, document number, revision, and date are visible. |
| T-02 | Footer | Copyright, confidentiality, and page number are visible. |
| T-03 | Table | Header row uses the configured dark background and white bold text. |
:::

# Code

The following block checks monospace rendering and spacing.

```lua
local function example(value)
  if value == nil then
    return "missing"
  end
  return tostring(value)
end
```

# Landscape Content

::: {.landscape}

## Wide Table

This section is wrapped in a landscape Div. It should start on a new page and
return to normal portrait pages afterward.

Table: Landscape verification matrix

| Requirement | Input | Expected Output | Status | Notes |
|---|---|---|---|---|
| Front page | Metadata block | Cover page with title and document information | Pass | Uses Pandoc template variables. |
| TOC | Headings | Contents page with dotted leaders | Pass | Uses section and subsection entries. |
| Standard table | Markdown pipe table | Styled longtable output | Pass | Handled by Lua filter. |
| Custom widths | Div attribute widths | Column widths follow provided ratios | Pass | Uses `.table-cols`. |
| Landscape | Div class landscape | Wide content appears on a landscape page | Pass | Uses `.landscape`. |

:::

# Final Section

This final section confirms that content after the landscape block returns to
normal portrait layout with the standard page header and footer.

::: {.landscape}

# Second Landscape Content

## Second Wide Table

This page verifies that a second landscape block still keeps the header and
footer at the top and bottom of the page.

Table: Second landscape verification matrix

| Area | Expected Result | Actual Check | Status |
|---|---|---|---|
| Page orientation | A4 landscape page size | Header remains horizontal at the top | Pass |
| Footer placement | Footer remains horizontal at the bottom | Page number stays in the bottom-right corner | Pass |
| Table width | Table uses the available landscape width | Columns remain readable | Pass |
| Restore behavior | Next page returns to portrait | Follow-up section uses portrait header and footer | Pass |

:::

# Post-Landscape Portrait Check

This page verifies that the document returns to normal portrait layout after a
second landscape page. The footer should sit at the bottom of the portrait page,
and the header should use the standard portrait width.
