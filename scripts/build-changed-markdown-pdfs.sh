#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

from_sha="${1:-${BASE_SHA:-}}"
to_sha="${2:-${HEAD_SHA:-HEAD}}"
pdf_engine="${PDF_ENGINE:-xelatex}"

if [[ "${BUILD_ALL_MARKDOWN:-0}" == "1" ]]; then
  markdown_files=()
  while IFS= read -r md_file; do
    markdown_files+=("$md_file")
  done < <(git ls-files '*.md')
else
  if [[ -z "$from_sha" ]]; then
    from_sha="$(git rev-parse "${to_sha}^")"
  fi

  if [[ "$from_sha" =~ ^0+$ ]]; then
    from_sha="$(git rev-list --max-parents=0 "$to_sha")"
  fi

  markdown_files=()
  while IFS= read -r md_file; do
    markdown_files+=("$md_file")
  done < <(git diff --name-only --diff-filter=AMR "$from_sha" "$to_sha" -- '*.md')
fi

if [[ "${#markdown_files[@]}" -eq 0 ]]; then
  echo "No changed Markdown files to build."
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

  echo "Building $output_pdf from $md_file"
  pandoc "$md_file" \
    --from=markdown+fenced_divs+link_attributes+table_captions \
    --template=Pandoc/template.tex \
    --lua-filter=Pandoc/style-filter.lua \
    --pdf-engine="$pdf_engine" \
    --resource-path="$resource_path" \
    --syntax-highlighting=tango \
    -o "$output_pdf"
done
