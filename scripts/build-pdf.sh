#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA_FILE="${1:-metadata/product.yaml}"
DOCUMENT_ARG="${2:-docs/apt-product.md}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"

cd "$ROOT_DIR"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc is required but was not found in PATH." >&2
  exit 1
fi

if [ ! -f "$METADATA_FILE" ]; then
  echo "Metadata file not found: $METADATA_FILE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo local)"
SAFE_BRANCH_NAME="$(printf "%s" "$BRANCH_NAME" | tr '/[:space:]' '-')"

build_document() {
  local document_file="$1"
  local document_name
  local output_file

  if [ ! -f "$document_file" ]; then
    echo "Document file not found: $document_file" >&2
    exit 1
  fi

  document_name="$(basename "$document_file" .md)"
  output_file="$OUTPUT_DIR/$document_name-$SAFE_BRANCH_NAME.pdf"

  pandoc \
    --from markdown+yaml_metadata_block+fenced_divs+pipe_tables \
    --metadata-file "$METADATA_FILE" \
    --include-in-header templates/company.tex \
    --lua-filter templates/company.lua \
    --pdf-engine xelatex \
    --toc \
    --number-sections \
    --output "$output_file" \
    "$document_file"

  echo "$output_file"
}

if [ "$DOCUMENT_ARG" = "--all" ]; then
  for document_file in docs/*.md; do
    build_document "$document_file"
  done
else
  build_document "$DOCUMENT_ARG"
fi
