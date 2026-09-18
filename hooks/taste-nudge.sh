#!/bin/bash
# PostToolUse[Edit|Write] reminder toward agents-with-taste (Emil Kowalski's design-engineering
# skill family), made finding-aware: runs impeccable's own detector directly on the just-edited
# file (not impeccable's cache - reading a separate hook's cache would race whichever hook the
# harness happens to run second; this sidesteps the race entirely at the cost of scanning the
# file twice when impeccable's own project-local hook also runs) and tailors the nudge to what it
# actually found, instead of always showing the same generic line. A hook can inject context, not
# invoke a skill directly - the actual call to load a skill stays a judgment call each time; this
# only makes both the reminder AND its content deterministic instead of relying on memory.
#
# This hook is registered GLOBALLY by this plugin (hooks/hooks.json) - it runs in every project
# the moment the plugin is installed, unlike impeccable's own hook which needs a project-local
# install to exist at all. Both facts matter here: impeccable may or may not be available for
# CLAUDE_PROJECT_DIR, project-locally or only globally, or not at all - this script degrades
# through all three rather than assuming any one of them.
#
# Fires once per session (a sentinel keyed by session_id), matching agents-with-taste's own
# stated cadence on an already-shipped surface: "asks once per project before applying, then
# remembers the answer" - every edit would be noise.
set -euo pipefail

INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null || true)"
SESSION="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || true)"

[ -z "$FILE" ] && exit 0

case "$FILE" in
  *.tsx|*.jsx|*.vue|*.svelte|*.astro|*.css|*.scss|*.sass|*.less|*.html) ;;
  *) exit 0 ;;
esac

SENTINEL="/tmp/claude-taste-nudge-${SESSION}"
[ -f "$SENTINEL" ] && exit 0

# agents-with-taste's own per-project consent gate - "declined" is an explicit, considered
# answer, not an oversight, and re-nudging around it every session would just be nagging past a
# decision that was already made deliberately.
GATE="${CLAUDE_PROJECT_DIR:-.}/.agents-with-taste/state.local.json"
if [ -f "$GATE" ]; then
  STATUS="$(jq -r '.status // empty' "$GATE" 2>/dev/null || true)"
  if [ "$STATUS" = "declined" ]; then
    touch "$SENTINEL"
    exit 0
  fi
fi
touch "$SENTINEL"

# Three-way fallback: this project's own local install, this MACHINE's global install, or none.
# Unlike a per-project hand-wired version of this hook, this one is installed once for every
# project on the machine, so it cannot assume CLAUDE_PROJECT_DIR has impeccable installed at all.
IMPECCABLE=""
for candidate in \
  "${CLAUDE_PROJECT_DIR:-.}/.claude/skills/impeccable/scripts/impeccable" \
  "$HOME/.claude/skills/impeccable/scripts/impeccable"; do
  if [ -x "$candidate" ]; then
    IMPECCABLE="$candidate"
    break
  fi
done
if [ -z "$IMPECCABLE" ] && command -v impeccable >/dev/null 2>&1; then
  IMPECCABLE="$(command -v impeccable)"
fi

FINDINGS="[]"
if [ -n "$IMPECCABLE" ] && [ -f "$FILE" ]; then
  # `detect` exits 2 (not 0) when it finds real issues - that is a MEANINGFUL result, not a
  # failure, and its JSON is still on stdout either way. `|| echo "[]"` INSIDE the substitution
  # would run on that exit 2 too, concatenating both branches' stdout into garbage. `|| true`
  # OUTSIDE the substitution captures stdout unconditionally and only neutralizes set -e.
  FINDINGS="$("$IMPECCABLE" detect --json "$FILE" 2>/dev/null)" || true
  echo "$FINDINGS" | jq -e . >/dev/null 2>&1 || FINDINGS="[]"
fi

# Loose keyword match on the antipattern id, deliberately not an exhaustive enum - impeccable's
# rule set is proprietary and can grow; a substring match on the motion-shaped ones is more
# robust to that than a hardcoded list that silently stops matching new rule ids.
MOTION_COUNT="$(echo "$FINDINGS" | jq '[.[] | select(.antipattern | test("bounce|easing|animat|motion|transition|spring"; "i"))] | length' 2>/dev/null || echo 0)"
TOTAL_COUNT="$(echo "$FINDINGS" | jq 'length' 2>/dev/null || echo 0)"

if [ "${MOTION_COUNT:-0}" -gt 0 ] 2>/dev/null; then
  IDS="$(echo "$FINDINGS" | jq -r '[.[] | select(.antipattern | test("bounce|easing|animat|motion|transition|spring"; "i")) | .antipattern] | unique | join(", ")')"
  MSG="Impeccable flagged a motion/easing issue in this UI file ($IDS). Consider the animate or review-animations skill specifically - Emil Kowalski's motion-craft judgment - before finishing this session's UI work."
elif [ "${TOTAL_COUNT:-0}" -gt 0 ] 2>/dev/null; then
  IDS="$(echo "$FINDINGS" | jq -r '[.[] | .antipattern] | unique | join(", ")')"
  MSG="Impeccable flagged visual design issues in this UI file ($IDS). Consider the emil-design-eng or apple-design skill - Emil Kowalski's design-engineering judgment - before finishing this session's UI work."
elif [ -n "$IMPECCABLE" ]; then
  MSG="This session touched UI code, and impeccable's scan came back clean here. If any of this session's work is new UI, animation, micro-interaction, or game-feel creation - not just a mechanical fix - consider loading the agents-with-taste skill (Emil Kowalski's design-engineering judgment) before finishing. Shown once per session."
else
  MSG="This session touched UI code. impeccable isn't set up for this project, so this reminder can't point at a specific finding - if any of this session's work is new UI, animation, micro-interaction, or game-feel creation, consider loading the agents-with-taste skill (Emil Kowalski's design-engineering judgment) before finishing. Shown once per session."
fi

jq -n --arg msg "$MSG" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$msg}}'
