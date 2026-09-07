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
cp -R "$SCRIPT_DIR/.claude/hooks" "$TARGET_DIR/.claude/"
echo "  - copied .claude/agents/ and .claude/hooks/ (always overwritten — these are template-owned, no per-project state lives in them)"
echo "  - the local test-gate hook is inert until devops-secops-engineer wires it up (asks once, see CONTEXT.md §6)"
echo "  - this template does not create a CI/CD pipeline — it assumes your project already has one"

if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
  python3 - "$SCRIPT_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json" <<'PYEOF'
import json, sys
template_path, target_path = sys.argv[1], sys.argv[2]
template = json.load(open(template_path))
target = json.load(open(target_path))
target.setdefault("$schema", template.get("$schema"))
perms = target.setdefault("permissions", {})
for key in ("ask", "deny", "allow"):
    template_list = template.get("permissions", {}).get(key, [])
    if not template_list:
        continue
    target_list = perms.setdefault(key, [])
    for entry in template_list:
        if entry not in target_list:
            target_list.append(entry)
json.dump(target, open(target_path, "w"), indent=2)
open(target_path, "a").write("\n")
PYEOF
  echo "  - merged .claude/settings.json: added any new base rules from the template, kept everything you'd already added (hooks, extra rules)"
else
  cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
  echo "  - copied .claude/settings.json"
fi

cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
echo "  - copied CLAUDE.md"

if [ -f "$TARGET_DIR/CONTEXT.md" ]; then
  echo "  - CONTEXT.md already exists in $TARGET_DIR, leaving it untouched"
else
  cp "$SCRIPT_DIR/CONTEXT.md.template" "$TARGET_DIR/CONTEXT.md"
  echo "  - created CONTEXT.md from template — fill it in with this project's stack"
fi

echo "Done. Note: this is a one-time copy, not a link — re-run this script to pull future updates."
