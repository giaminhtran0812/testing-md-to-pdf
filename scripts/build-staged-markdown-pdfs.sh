#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

export PATH="/opt/homebrew/bin:/usr/local/bin:/c/Program Files/Pandoc:/c/ProgramData/chocolatey/bin:$HOME/scoop/shims:$HOME/.cargo/bin:$PATH"

pdf_engine="${PDF_ENGINE:-tectonic}"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc is required to build PDFs." >&2
  exit 1
fi

if ! command -v "$pdf_engine" >/dev/null 2>&1; then
  echo "$pdf_engine is required to build PDFs." >&2
  exit 1
fi

markdown_files=()
while IFS= read -r md_file; do
  markdown_files+=("$md_file")
done < <(git diff --cached --name-only --diff-filter=AMR -- '*.md')

if [[ "${#markdown_files[@]}" -eq 0 ]]; then
  echo "No staged Markdown files to build."
  exit 0
fi

for md_file in "${markdown_files[@]}"; do
  if [[ ! -f "$md_file" ]]; then
    echo "Skipping missing Markdown file: $md_file"
    continue
  fi

  if [[ ! -s "$md_file" ]]; then
    echo "Skipping empty Markdown file: $md_file"
    continue
  fi

  output_pdf="${md_file%.md}.pdf"
  resource_path=".:$(dirname "$md_file")"

  echo "Building $output_pdf from staged Markdown file $md_file"
  pandoc "$md_file" \
    --from=markdown+fenced_divs+link_attributes+table_captions \
    --template=Pandoc/template.tex \
    --lua-filter=Pandoc/style-filter.lua \
    --pdf-engine="$pdf_engine" \
    --resource-path="$resource_path" \
    --syntax-highlighting=tango \
    -o "$output_pdf"

  git add "$output_pdf"
done
