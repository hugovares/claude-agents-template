#!/usr/bin/env bash
# Runs this project's test suite. Auto-detects a common convention;
# override by hardcoding your real command below if detection guesses wrong.
#
# Exit codes:
#   0 - tests passed, OR no test suite was found (nothing to enforce yet)
#   1 - tests ran and failed
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

# --- Override point: uncomment and set your exact command if auto-detection
# --- picks the wrong one for this project.
# TEST_CMD="npm run test:ci"

if [ -z "${TEST_CMD:-}" ]; then
  if [ -f package.json ] && grep -q '"test"' package.json; then
    TEST_CMD="npm test"
  elif [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -f setup.cfg ]; then
    TEST_CMD="pytest"
  elif [ -f go.mod ]; then
    TEST_CMD="go test ./..."
  fi
fi

if [ -z "${TEST_CMD:-}" ]; then
  echo "run-tests.sh: no recognized test setup found (package.json/pyproject.toml/go.mod) — nothing to enforce yet." >&2
  exit 0
fi

echo "run-tests.sh: running \`$TEST_CMD\`" >&2
if eval "$TEST_CMD"; then
  exit 0
else
  exit 1
fi
