#!/bin/bash
# PostToolUse[Edit|Write], once per session, on the first UI-file edit. Two jobs:
#
# 1. First UI edit in a project where impeccable's own auto-check isn't wired and the taste gate is
#    undecided: point Claude at reference/first-ui-edit.md, which asks the user ONCE and, on yes,
#    wires impeccable (hooks/wire-impeccable.sh), re-checks the change just made, and applies
#    agents-with-taste to it - so the first edit is covered, not only the ones after it.
# 2. Everywhere else: a finding-aware nudge toward agents-with-taste. It runs impeccable's detector
#    on the just-edited file itself (not impeccable's cache - reading another hook's cache would
#    race whichever hook the harness runs second) and names the guide that fits what it found.
#
# Registered globally by this plugin, so it cannot assume impeccable exists for this project: the
# detector lookup falls back project-local -> this machine's global install -> PATH -> none.
# A hook can only inject context; loading the skill stays Claude's call.
set -euo pipefail

INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null || true)"
SESSION="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || true)"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

[ -z "$FILE" ] && exit 0

case "$FILE" in
  *.tsx|*.jsx|*.vue|*.svelte|*.astro|*.css|*.scss|*.sass|*.less|*.html) ;;
  *) exit 0 ;;
esac

SENTINEL="/tmp/claude-taste-nudge-${SESSION}"
[ -f "$SENTINEL" ] && exit 0
touch "$SENTINEL"

# Taste is on by default; only an explicit "declined" silences it.
STATUS=""
GATE="$PROJECT/.agents-with-taste/state.local.json"
[ -f "$GATE" ] && STATUS="$(jq -r '.status // empty' "$GATE" 2>/dev/null || true)"
[ "$STATUS" = "declined" ] && exit 0

IMPECCABLE=""
for candidate in \
  "$PROJECT/.claude/skills/impeccable/scripts/impeccable" \
  "$HOME/.claude/skills/impeccable/scripts/impeccable"; do
  if [ -x "$candidate" ]; then
    IMPECCABLE="$candidate"
    break
  fi
done
if [ -z "$IMPECCABLE" ] && command -v impeccable >/dev/null 2>&1; then
  IMPECCABLE="$(command -v impeccable)"
fi

# "Wired" = impeccable's own hook is registered for this project, not merely installed somewhere.
WIRED=0
if [ -x "$PROJECT/.claude/skills/impeccable/scripts/impeccable" ] \
  && grep -q 'skills/impeccable/scripts/impeccable' "$PROJECT/.claude/settings.local.json" "$PROJECT/.claude/settings.json" 2>/dev/null; then
  WIRED=1
fi

FINDINGS="[]"
if [ -n "$IMPECCABLE" ] && [ -f "$FILE" ]; then
  # `detect` exits 2 (not 0) when it finds real issues - a meaningful result, with the JSON still
  # on stdout. `|| true` OUTSIDE the substitution keeps that stdout; `|| echo "[]"` inside it would
  # concatenate both branches into garbage.
  FINDINGS="$("$IMPECCABLE" detect --json "$FILE" 2>/dev/null)" || true
  echo "$FINDINGS" | jq -e . >/dev/null 2>&1 || FINDINGS="[]"
fi

# Loose keyword match on antipattern ids - impeccable's rule set can grow, and a substring match on
# the motion-shaped ones survives new ids that a hardcoded list would silently miss.
MOTION_RE='bounce|easing|animat|motion|transition|spring'
MOTION_IDS="$(echo "$FINDINGS" | jq -r --arg re "$MOTION_RE" '[.[] | select(.antipattern | test($re; "i")) | .antipattern] | unique | join(", ")' 2>/dev/null || true)"
ALL_IDS="$(echo "$FINDINGS" | jq -r '[.[] | .antipattern] | unique | join(", ")' 2>/dev/null || true)"
NAME="$(basename "$FILE")"

if [ "$WIRED" = 0 ] && [ -z "$STATUS" ]; then
  if [ -n "$ALL_IDS" ]; then SCAN=" impeccable's scan of $NAME found: $ALL_IDS."
  elif [ -n "$IMPECCABLE" ]; then SCAN=" impeccable's scan of $NAME came back clean."
  else SCAN=" impeccable isn't installed on this machine, so there is no scan."
  fi
  MSG="[taste-detector] First UI edit in this project, and impeccable's auto-check isn't set up here.$SCAN Before your next step, follow $ROOT/skills/agents-with-taste/reference/first-ui-edit.md: ask the user once; on yes run \"$ROOT/hooks/wire-impeccable.sh\" \"$PROJECT\", re-check every UI file changed this session${IMPECCABLE:+ with \"$IMPECCABLE\" detect --json <files>}, and apply taste-detector:agents-with-taste to that same change."
elif [ -n "$MOTION_IDS" ]; then
  MSG="[taste-detector] impeccable flagged motion issues in $NAME ($MOTION_IDS). Load taste-detector:agents-with-taste now and fix them with its animate and emil-design-eng guides before continuing."
elif [ -n "$ALL_IDS" ]; then
  MSG="[taste-detector] impeccable flagged $ALL_IDS in $NAME. If any of them touch press/hover feedback, transitions, or feel, load taste-detector:agents-with-taste (emil-design-eng guide) while fixing them."
else
  MSG="[taste-detector] UI file edited. If this change adds or alters motion, press/hover feedback, transitions, or game feel, load taste-detector:agents-with-taste before your next edit; text- or layout-only changes need nothing further."
fi

jq -n --arg msg "$MSG" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$msg}}'
