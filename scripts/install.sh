#!/usr/bin/env bash
# One-time copy of this template into another project — no submodule required.
# Usage: ./scripts/install.sh /path/to/my-new-project
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory '$TARGET_DIR' does not exist." >&2
  exit 1
fi

echo "Installing claude-agents-template into $TARGET_DIR"

mkdir -p "$TARGET_DIR/.claude"
cp -R "$SCRIPT_DIR/.claude/agents" "$TARGET_DIR/.claude/"
cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
echo "  - copied .claude/agents/ and .claude/settings.json"

cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
echo "  - copied CLAUDE.md"

if [ -f "$TARGET_DIR/CONTEXT.md" ]; then
  echo "  - CONTEXT.md already exists in $TARGET_DIR, leaving it untouched"
else
  cp "$SCRIPT_DIR/CONTEXT.md.template" "$TARGET_DIR/CONTEXT.md"
  echo "  - created CONTEXT.md from template — fill it in with this project's stack"
fi

echo "Done. Note: this is a one-time copy, not a link — re-run this script to pull future updates."
