#!/usr/bin/env bash
# Boring, deterministic consistency check — not a behavioral test (see SCENARIOS.md
# for that). Catches the kind of mistake careful reading would eventually find:
# a renamed/removed agent that some other file still refers to by its old name.
#
# Checks:
#   1. Each agent file's frontmatter `name:` matches its filename.
#   2. orchestrator-architect's Agent() allowlist matches the real set of
#      agent files exactly (minus itself).
#   3. No backtick-wrapped, agent-name-shaped token in the docs fails to
#      resolve to a real agent file (a short, explicit exceptions list
#      covers known non-agent tokens like `data-testid`).
#
# Usage: ./scripts/check-agent-refs.sh
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

AGENTS_DIR=".claude/agents"
ORCHESTRATOR="$AGENTS_DIR/orchestrator-architect.md"
FAIL=0

echo "== 1. Frontmatter name vs. filename =="
for f in "$AGENTS_DIR"/*.md; do
  base=$(basename "$f" .md)
  fm_name=$(grep -m1 '^name:' "$f" | sed 's/^name: *//')
  if [ "$fm_name" != "$base" ]; then
    echo "MISMATCH: $f has \`name: $fm_name\` (expected \`$base\`)"
    FAIL=1
  fi
done
[ "$FAIL" = 0 ] && echo "OK"

echo
echo "== 2. orchestrator-architect's Agent() allowlist =="
real_agents=$(ls "$AGENTS_DIR" | sed 's/\.md$//' | sort)
expected=$(echo "$real_agents" | grep -v '^orchestrator-architect$')
allowlist=$(grep '^tools:' "$ORCHESTRATOR" | grep -oE 'Agent\([^)]+\)' | sed 's/Agent(//;s/)//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort)

if [ "$allowlist" != "$expected" ]; then
  echo "MISMATCH between Agent() allowlist and real agent files:"
  diff <(echo "$expected") <(echo "$allowlist")
  FAIL=1
else
  echo "OK"
fi

echo
echo "== 3. Stale agent-name references in docs =="
# Kebab-case tokens that legitimately look like agent names but aren't.
KNOWN_NON_AGENTS="claude-agents-template data-testid data-analytics-id"

mentioned=$(grep -rohE '`[a-z]+(-[a-z]+)+`' --include="*.md" . 2>/dev/null | grep -v '^\./\.git/' | tr -d '`' | sort -u)
STALE=0
for token in $mentioned; do
  if echo "$real_agents" | grep -qx "$token"; then
    continue
  fi
  skip=0
  for known in $KNOWN_NON_AGENTS; do
    [ "$token" = "$known" ] && skip=1 && break
  done
  [ "$skip" = 1 ] && continue
  echo "REVIEW: \`$token\` doesn't match a real agent file — confirm it's not a stale rename, or add it to KNOWN_NON_AGENTS in this script if it's an intentional non-agent term."
  STALE=1
done
[ "$STALE" = 0 ] && echo "OK"

echo
if [ "$FAIL" = 1 ] || [ "$STALE" = 1 ]; then
  echo "FAILED — see above."
  exit 1
else
  echo "All structural checks passed."
fi
