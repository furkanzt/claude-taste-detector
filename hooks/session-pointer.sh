#!/bin/bash
# SessionStart: one always-loaded pointer line, so motion/feel work reaches agents-with-taste
# deterministically instead of depending on its description out-matching impeccable's on the skill
# menu. Injected in repos that contain UI code and in empty folders (new work); silent in
# backend-only repos and wherever the taste gate says "declined".
set -uo pipefail

cat >/dev/null  # drain the hook payload; nothing in it is needed
P="${CLAUDE_PROJECT_DIR:-$PWD}"

GATE="$P/.agents-with-taste/state.local.json"
if [ -f "$GATE" ] && [ "$(jq -r '.status // empty' "$GATE" 2>/dev/null)" = "declined" ]; then
  exit 0
fi

if [ -z "$(find "$P" -mindepth 1 -maxdepth 1 -not -name '.*' -print -quit 2>/dev/null)" ]; then
  MSG="[taste-detector] Empty project. If this work creates UI or a game, load the taste-detector:agents-with-taste skill for every motion, feedback, or feel decision - impeccable leads the overall design."
elif [ -n "$(find "$P" -maxdepth 4 \
    \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name vendor -o -name bin -o -name obj \) -prune \
    -o -type f \( -name '*.tsx' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' -o -name '*.astro' \
    -o -name '*.css' -o -name '*.scss' -o -name '*.html' -o -name '*.cshtml' -o -name '*.swift' \) -print -quit 2>/dev/null)" ]; then
  MSG="[taste-detector] This repo has UI code. For any motion, animation, transition, press/hover feedback, gesture, game-feel, or touch-feel decision, load the taste-detector:agents-with-taste skill before writing that code - impeccable decides where motion goes, its guides decide how it moves."
else
  exit 0
fi

jq -n --arg msg "$MSG" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$msg}}'
