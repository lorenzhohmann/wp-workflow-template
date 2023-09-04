#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

directory="$1"

for file in "$directory"/*.css "$directory"/*.js; do
  if [[ -f "$file" ]]; then
    minify "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
done