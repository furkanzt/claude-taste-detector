#!/bin/bash
# Pipe-tests the three hook scripts against throwaway fixture projects.
# usage: tests/hooks.test.sh      (exit 0 = all pass)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" /tmp/claude-taste-nudge-tdtest-*' EXIT
IMP="$HOME/.claude/skills/impeccable/scripts/impeccable"
PASS=0; FAIL=0

check() {  # check <name> <haystack> <needle|"<empty>">
  if [ "$3" = "<empty>" ]; then
    if [ -z "$2" ]; then PASS=$((PASS+1)); echo "ok   $1"; else FAIL=$((FAIL+1)); echo "FAIL $1 - expected no output, got: ${2:0:160}"; fi
  elif [[ "$2" == *"$3"* ]]; then PASS=$((PASS+1)); echo "ok   $1"
  else FAIL=$((FAIL+1)); echo "FAIL $1 - expected '$3' in: ${2:0:200}"; fi
}
pointer() { echo '{}' | CLAUDE_PROJECT_DIR="$1" "$ROOT/hooks/session-pointer.sh"; }
nudge() {  # nudge <project> <file> <session>
  echo "{\"session_id\":\"tdtest-$3\",\"tool_input\":{\"file_path\":\"$2\"}}" \
    | CLAUDE_PROJECT_DIR="$1" CLAUDE_PLUGIN_ROOT="$ROOT" "$ROOT/hooks/taste-nudge.sh"
}
decline() { mkdir -p "$1/.agents-with-taste"; echo '{"status":"declined"}' > "$1/.agents-with-taste/state.local.json"; }

# --- session-pointer.sh
mkdir -p "$TMP/empty" "$TMP/ui/app" "$TMP/backend" "$TMP/ui-declined/app"
touch "$TMP/ui/app/page.tsx" "$TMP/backend/main.py" "$TMP/ui-declined/app/page.tsx"
decline "$TMP/ui-declined"
check "pointer: empty folder gets the new-project line" "$(pointer "$TMP/empty")" "Empty project"
check "pointer: UI repo gets the pointer" "$(pointer "$TMP/ui")" "This repo has UI code"
check "pointer: backend-only repo stays silent" "$(pointer "$TMP/backend")" "<empty>"
check "pointer: declined repo stays silent" "$(pointer "$TMP/ui-declined")" "<empty>"

# --- taste-nudge.sh
mkdir -p "$TMP/fresh/app"; echo 'export default 1' > "$TMP/fresh/app/page.tsx"
check "nudge: non-UI file is ignored" "$(nudge "$TMP/fresh" "$TMP/fresh/lib.ts" a)" "<empty>"
OUT="$(nudge "$TMP/fresh" "$TMP/fresh/app/page.tsx" b)"
check "nudge: unwired + undecided starts the first-edit flow" "$OUT" "First UI edit in this project"
check "nudge: first-edit flow names the wire script" "$OUT" "hooks/wire-impeccable.sh"
check "nudge: fires once per session" "$(nudge "$TMP/fresh" "$TMP/fresh/app/page.tsx" b)" "<empty>"
decline "$TMP/ui-declined"
check "nudge: declined project stays silent" "$(nudge "$TMP/ui-declined" "$TMP/ui-declined/app/page.tsx" c)" "<empty>"
mkdir -p "$TMP/consented/app/.." "$TMP/consented/.agents-with-taste"; echo '{"status":"consented"}' > "$TMP/consented/.agents-with-taste/state.local.json"
echo 'export default 1' > "$TMP/consented/app/page.tsx"
check "nudge: consented-but-unwired skips the question" "$(nudge "$TMP/consented" "$TMP/consented/app/page.tsx" d)" "UI file edited"

# --- wire-impeccable.sh
if [ -x "$IMP" ]; then
  mkdir -p "$TMP/wire/.claude" && git -C "$TMP/wire" init -q
  echo '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo keep-me"}]}]}}' > "$TMP/wire/.claude/settings.local.json"
  OUT="$("$ROOT/hooks/wire-impeccable.sh" "$TMP/wire")"
  check "wire: links the global install" "$OUT" "linked .claude/skills/impeccable"
  check "wire: registers both hooks" "$OUT" "PostToolUse + Stop"
  check "wire: gitignores the link" "$(cat "$TMP/wire/.gitignore")" "/.claude/skills/impeccable"
  check "wire: keeps unrelated existing hooks" "$(cat "$TMP/wire/.claude/settings.local.json")" "keep-me"
  OUT="$("$ROOT/hooks/wire-impeccable.sh" "$TMP/wire")"
  check "wire: second run is idempotent" "$OUT" "already registered"
  check "wire: no duplicate gitignore lines" "$(grep -c impeccable "$TMP/wire/.gitignore")" "1"

  printf '.t { background: linear-gradient(45deg,#f0f,#0ff); -webkit-background-clip: text; color: transparent; }\n' > "$TMP/wire/bad.css"
  check "nudge: wired project names impeccable's finding" "$(nudge "$TMP/wire" "$TMP/wire/bad.css" e)" "gradient-text"
  echo '.ok { color: #111; }' > "$TMP/wire/ok.css"
  check "nudge: wired + clean gives the conditional pointer" "$(nudge "$TMP/wire" "$TMP/wire/ok.css" f)" "text- or layout-only changes need nothing further"
  mkdir -p "$TMP/wire2" && git -C "$TMP/wire2" init -q
  printf '.t { background: linear-gradient(45deg,#f0f,#0ff); -webkit-background-clip: text; color: transparent; }\n' > "$TMP/wire2/first.css"
  check "wire: re-checks the files it is given" "$("$ROOT/hooks/wire-impeccable.sh" "$TMP/wire2" "$TMP/wire2/first.css")" "re-checked 1 file(s): gradient-text"
  echo '.ok { color: #111; }' > "$TMP/wire2/clean.css"
  check "wire: reports a clean re-check" "$("$ROOT/hooks/wire-impeccable.sh" "$TMP/wire2" "$TMP/wire2/clean.css")" "re-checked 1 file(s): clean"
  mkdir -p "$TMP/nogit"
  check "wire: outside git it leaves version control alone" "$("$ROOT/hooks/wire-impeccable.sh" "$TMP/nogit")" "not a git repo"
  check "wire: outside git it writes no .gitignore" "$([ -e "$TMP/nogit/.gitignore" ] && echo present)" "<empty>"
else
  echo "skip wire-impeccable tests - impeccable isn't installed globally at $IMP"
fi

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
