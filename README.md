# APT Documentation

This repository stores the Markdown source for APT product documentation and project-specific documentation derived from it.

The intended workflow is:

- `main` contains the baseline APT product documentation.
- `project/<name>` branches contain project/customer-specific documentation.
- Markdown is the source of truth.
- PDF files are generated from Markdown using Pandoc, LaTeX, and the company style files in `templates/`.
- Generated PDFs are build outputs and should be uploaded to Teamcenter after review/approval.

## Repository Layout

```text
docs/
  apt-product.md
  operation-manual.md
metadata/
  product.yaml
  project.example.yaml
templates/
  company.tex
  company.lua
scripts/
  build-pdf.sh
.github/workflows/
  build-pdf.yml
```

## Local PDF Build

Install Pandoc and a LaTeX distribution first.

On macOS, one practical setup is:

```bash
brew install pandoc
brew install --cask mactex-no-gui
```

Then build the product documentation:

```bash
./scripts/build-pdf.sh
```

Build a specific document with project metadata:

```bash
./scripts/build-pdf.sh metadata/project.example.yaml docs/operation-manual.md
```

Build every document under `docs/`:

```bash
./scripts/build-pdf.sh metadata/product.yaml --all
```

The generated PDF is written to `dist/`.

## Multiple Documents

Use one Markdown file per controlled document.

For example:

```text
docs/apt-product.md
docs/operation-manual.md
docs/maintenance-manual.md
docs/factory-acceptance-test.md
```

Avoid splitting one document into many small section files unless the document becomes too large to review comfortably. This keeps authoring, review, and Teamcenter upload closer to how the final PDF is controlled.

## Branching Model

Use `main` as the product APT documentation baseline.

Create a project branch from the product version/tag used by that project:

```bash
git checkout main
git tag apt-doc-v1.0
git checkout -b project/customer-a apt-doc-v1.0
```

For project changes, edit the project branch and use a project metadata file, for example:

```text
metadata/project.customer-a.yaml
```

Keep project-specific changes isolated from the reusable product documentation unless they should become part of the product baseline.

## CI PDF Build

GitHub Actions builds PDFs only from update branches:

- `update`
- `update/**`

The protected product/project branches, such as `main` and `project/<name>`, should not run the PDF build directly. Create an update branch, open a pull request, review the generated PDF artifact, then merge after approval.

The workflow also requires changes to files that can affect the generated PDF:

- `docs/**/*.md`
- `metadata/**/*.yaml`
- `templates/**`
- `scripts/build-pdf.sh`
- `.github/workflows/build-pdf.yml`

The PDF is uploaded as a workflow artifact. Teamcenter upload should be added later as a separate controlled step after credentials, document numbering, and release rules are clear.
