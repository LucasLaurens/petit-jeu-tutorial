#!/usr/bin/env bash
# Every quality gate, in the order CI runs them. Same script locally and in CI.
set -euo pipefail

GODOT="${GODOT:-godot}"
SOURCES=(creer-un-jeu-sur-godot-facilement-assets-main/scripts test)
# Godot and GUT both exit 0 when a script fails to parse (GUT then skips the file),
# so the log is the only reliable signal.
FAILURE_PATTERN='SCRIPT ERROR|Parse Error|GUT ERROR|Ignoring script'

run_godot() {
	local log
	log="$(mktemp)"
	"$GODOT" --headless --path . "$@" 2>&1 | tee "$log"
	if grep -qE "$FAILURE_PATTERN" "$log"; then
		echo "check.sh: script errors found, see log above." >&2
		exit 1
	fi
}

echo "==> Format"
gdformat --check "${SOURCES[@]}"

echo "==> Lint"
gdlint "${SOURCES[@]}"

echo "==> Static analysis (import)"
run_godot --import

echo "==> Tests"
run_godot -s addons/gut/gut_cmdln.gd
