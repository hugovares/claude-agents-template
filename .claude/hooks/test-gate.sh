#!/usr/bin/env bash
# PreToolUse hook: runs before Claude Code executes `git commit` OR `git push`.
# Blocks the command (exit 2) if the test suite fails — this is a real,
# mechanical gate, not a prompt-based rule an agent could talk itself out of.
#
# Wired up in .claude/settings.json under hooks.PreToolUse, matched to
# Bash(git commit *) and Bash(git push *) — two entries, same script. Only
# active once devops-secops-engineer has set that up with the user's
# explicit, one-time opt-in (see CONTEXT.md §6).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if "$SCRIPT_DIR/run-tests.sh"; then
  exit 0
else
  echo "Tests failed — blocked by .claude/hooks/test-gate.sh." >&2
  echo "Fix the failing tests, or run tests manually to see full output, then retry." >&2
  exit 2
fi
