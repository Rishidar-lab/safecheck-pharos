#!/usr/bin/env bash
# Build the submission zip for Anvita Flow. The skill FOLDER must be the top-level entry
# in the zip (not its contents), and build/lib artifacts must be excluded.
set -euo pipefail
cd "$(dirname "$0")/../.."   # parent of safecheck-skill

FOLDER="safecheck-skill"
OUT="safecheck-skill.zip"
rm -f "$OUT"

zip -r "$OUT" "$FOLDER" \
  -x "$FOLDER/.git/*" \
  -x "$FOLDER/lib/*" \
  -x "$FOLDER/out/*" \
  -x "$FOLDER/cache/*" \
  -x "$FOLDER/broadcast/*" \
  -x "$FOLDER/.env*" \
  > /dev/null

echo "Built $OUT"
echo "Top-level entries (must show '$FOLDER/' as the root):"
unzip -l "$OUT" | awk '{print $4}' | grep -v '^$' | cut -d/ -f1 | sort -u
