---
title: "Aptara MCS"
subtitle: "Standard Product Test Document"
doc_number: "AAA693120-TEST"
revision: "015"
author: "Codex"
date: "July 7, 2026"
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

## Nomenclature and Abbreviations

::: {.nomenclature width="0.25,0.75"}
| Abbreviation | Spell out |
|---|---|
| API | Application Programming Interface |
| BOM | Bill of Materials |
| CIL | Component Information Library |
| CLI | Command Line Interface |
| CSV | Comma-Separated Values |
| GUI | Graphical User Interface |
| HTML | HyperText Markup Language |
| JSON | JavaScript Object Notation |
| MCS | Modular Control System |
| PDF | Portable Document Format |
| QA | Quality Assurance |
| RGB | Red, Green, Blue |
| SDK | Software Development Kit |
| SSRS | SQL Server Reporting Services |
| SVG | Scalable Vector Graphics |
| TEX | TeX Typesetting Source |
| TOC | Table of Contents |
| URI | Uniform Resource Identifier |
| URL | Uniform Resource Locator |
| XML | Extensible Markup wfewefawfwefwef |
:::

## Links and Cross References {#sec:links-cross-references}

This section tests common link formats: an inline external link to
[Baker Hughes](https://www.bakerhughes.com), an automatic URL
<https://www.bakerhughes.com>, an email link to
[documentation@example.com](mailto:documentation@example.com), a local file link
to [the random photo](randomphoto.jpg), and a reference-style link to
[Pandoc documentation][pandoc-docs].

Internal document links should jump to the target section, such as
[Figures](#figures), [Tables](#tables), and
[Unnumbered Sample Section](#unnumbered-sample-section).

Cross references should keep the section-based numbering in the PDF: see
Section \ref{figures}, Figure \ref{fig:bh-logo}, Figure \ref{fig:random-photo},
Table \ref{tbl:standard-two-column}, Table \ref{tbl:custom-width-table}, and
Table \ref{tbl:landscape-matrix}. Auto-numbered row references should also
resolve, for example Item \ref{itm:metadata-check} and Item
\ref{itm:release-approval}.

[pandoc-docs]: https://pandoc.org/MANUAL.html

### Scope

This section confirms that third-level headings render with the expected
spacing and typography.

> This is a block quote. It should remain readable and should not collide with
> surrounding body text or section headings.

# Unnumbered Sample Section {.unnumbered}

This heading uses Pandoc's `{.unnumbered}` attribute. It should render without a
section number while keeping the normal heading style.

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

![Baker Hughes logo test image](Pandoc/logo.png){#fig:bh-logo width=35%}

The figure above checks image placement, caption styling, and section-based
figure numbering.

![Random photo test image](randomphoto.jpg){#fig:random-photo width=45%}

The second figure checks a local image that sits beside this Markdown source
file.

# Tables

Table: Standard two-column table {#tbl:standard-two-column}

| Field | Value |
|---|---|
| Product | Aptara MCS |
| Document Number | AAA693120-TEST |
| Revision | 015 |
| Owner | Engineering Documentation |

Table: Standard three-column table {#tbl:standard-three-column}

| Step | Owner | Description |
|---|---|---|
| 1 | Engineering | Prepare source Markdown and metadata. |
| 2 | Documentation | Convert Markdown to PDF using the Pandoc template. |
| 3 | Review | Check front page, TOC, headers, footers, and tables. |

::: {.table-cols width="0.15,0.30,0.55"}
Table: Custom-width table using the style filter {#tbl:custom-width-table}

| ID | Area | Verification |
|---|---|---|
| T-01 | Header | Product, title, document number, revision, and date are visible. |
| T-02 | Footer | Copyright, confidentiality, and page number are visible. |
| T-03 | Table | Header row uses the configured dark background and white bold text. |
:::

::: {.auto-items .table-cols width="0.12,0.32,0.56" notes="(1) Metadata fields come from the document YAML block.|(2) Cross references are resolved by LaTeX labels generated by the Lua filter.|(3) Status cell colors are controlled by RGB values in the Markdown source."}
Table: Auto-numbered item table with colored cells {#tbl:auto-item-status}

| Item | Check | Status |
|---|---|---|
| {#itm:metadata-check} | Metadata revision and document fields (1) | [Ready]{rgb="221,239,234"} |
| {#itm:cross-reference-check} | Figure, table, and item cross references (2) | [Needs review]{rgb="255,242,204"} |
| {#itm:release-approval} | Final PDF approval before release (3) | [Blocked]{rgb="244,204,204"} |
:::

The auto-numbered item table should allow normal text to refer to individual
rows. For example, Item \ref{itm:metadata-check} checks metadata, Item
\ref{itm:cross-reference-check} checks references, and Item
\ref{itm:release-approval} tracks release approval.

Table: Long table spanning multiple pages {#tbl:long-table}

| Row | Category | Description |
|---|---|---|
| 01 | Long table | This row is part of a long table used to verify page breaks. |
| 02 | Long table | The header row should repeat when the table continues on the next page. |
| 03 | Long table | Captions should keep the Table a-b numbering format. |
| 04 | Long table | Body rows should remain inside the page margins. |
| 05 | Long table | The footer should stay at the bottom of each page. |
| 06 | Long table | This row adds enough content to force a page break. |
| 07 | Long table | This row adds enough content to force a page break. |
| 08 | Long table | This row adds enough content to force a page break. |
| 09 | Long table | This row adds enough content to force a page break. |
| 10 | Long table | This row adds enough content to force a page break. |
| 11 | Long table | This row adds enough content to force a page break. |
| 12 | Long table | This row adds enough content to force a page break. |
| 13 | Long table | This row adds enough content to force a page break. |
| 14 | Long table | This row adds enough content to force a page break. |
| 15 | Long table | This row adds enough content to force a page break. |
| 16 | Long table | This row adds enough content to force a page break. |
| 17 | Long table | This row adds enough content to force a page break. |
| 18 | Long table | This row adds enough content to force a page break. |
| 19 | Long table | This row adds enough content to force a page break. |
| 20 | Long table | This row adds enough content to force a page break. |
| 21 | Long table | This row adds enough content to force a page break. |
| 22 | Long table | This row adds enough content to force a page break. |
| 23 | Long table | This row adds enough content to force a page break. |
| 24 | Long table | This row adds enough content to force a page break. |
| 25 | Long table | This row adds enough content to force a page break. |
| 26 | Long table | This row adds enough content to force a page break. |
| 27 | Long table | This row adds enough content to force a page break. |
| 28 | Long table | This row adds enough content to force a page break. |
| 29 | Long table | This row adds enough content to force a page break. |
| 30 | Long table | This row adds enough content to force a page break. |
| 31 | Long table | This row adds enough content to force a page break. |
| 32 | Long table | This row adds enough content to force a page break. |
| 33 | Long table | This row adds enough content to force a page break. |
| 34 | Long table | This row adds enough content to force a page break. |
| 35 | Long table | This row adds enough content to force a page break. |
| 36 | Long table | This row adds enough content to force a page break. |
| 37 | Long table | This row adds enough content to force a page break. |
| 38 | Long table | This row adds enough content to force a page break. |
| 39 | Long table | This row adds enough content to force a page break. |
| 40 | Long table | This row adds enough content to force a page break. |
| 41 | Long table | This row adds enough content to force a page break. |
| 42 | Long table | This row adds enough content to force a page break. |
| 43 | Long table | This row adds enough content to force a page break. |
| 44 | Long table | This row adds enough content to force a page break. |
| 45 | Long table | This row confirms the long table can continue after a page break. |

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

Table: Landscape verification matrix {#tbl:landscape-matrix}

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

Table: Second landscape verification matrix {#tbl:second-landscape-matrix}

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
