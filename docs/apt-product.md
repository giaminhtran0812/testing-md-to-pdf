---
title: "APT Product Documentation"
subtitle: "Automatic Control System for Oil and Gas Production"
---

# Document Control

This document describes the baseline APT product documentation package.

Project-specific branches should update the metadata file and only change content that is required by the customer or project scope.

| Field | Value |
| --- | --- |
| Product | APT |
| Document type | Product baseline |
| Source branch | `main` |
| Output format | PDF |

::: pagebreak
:::

# Overview

APT is the reusable software product package for automatic control systems used in oil and gas production projects.

Historically, projects used similar hardware while software differed by customer and project requirements. APT standardizes the reusable software baseline so new projects can start from a controlled product package and apply only the required project-specific changes.

## Goals

- Maintain one controlled product documentation baseline.
- Allow project documentation to be derived from the product baseline.
- Keep Markdown as the editable source format.
- Generate release-ready PDFs using a repeatable build process.
- Prepare generated PDFs for later upload to Teamcenter.

# System Architecture

The APT documentation should describe both the reusable product baseline and the boundaries where project-specific configuration is expected.

Typical documentation areas include:

- Control system overview
- Hardware interfaces
- Software functions
- Communication protocols
- Operator interface
- Alarm and event handling
- Testing and acceptance criteria
- Maintenance and support information

Project branches should clearly identify deviations from the product baseline.

# Project Customization

Project-specific documentation should be maintained in a dedicated branch such as:

```text
project/customer-a
```

Recommended project metadata fields:

- Project name
- Customer name
- Facility or asset name
- APT baseline version
- Document number
- Revision
- Approval status

Project changes should be limited to customer requirements, project configuration, and approved deviations from the APT baseline.

# Release Process

The documentation release process should be controlled and repeatable.

1. Update Markdown source files.
2. Build the PDF locally or through GitHub Actions.
3. Review the generated PDF.
4. Approve the documentation revision.
5. Upload the approved PDF to Teamcenter.
6. Tag the released documentation version in Git.

Example product tag:

```text
apt-doc-v1.0
```

Example project tag:

```text
customer-a-doc-rev-a
```
