#!/usr/bin/env bash
set -euxo pipefail

# Check plantuml is in PATH
command -v plantuml

# Output
PNG=false
SVG=true

for i in ./*.dot; do
  if $PNG; then
    rm -f "${i%.dot}.png"
    plantuml -Tpng "$i";
  fi

  if $SVG; then
    rm -f "${i%.dot}.svg"
    plantuml -Tsvg "$i";
  fi
done

