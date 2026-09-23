#!/bin/bash
# Routing eval: runs the prompts in prompts.tsv headlessly and scores whether Claude reached
# agents-with-taste and the right guide (score.py). Proves routing, not just configuration.
#
# usage: tests/eval/run.sh <label> <installed|repo> [model ...]
#   installed  the taste-detector plugin as installed on this machine (a baseline)
#   repo       this working tree, via --plugin-dir, with the installed copy disabled
#   models     default: claude-sonnet-5 claude-opus-5-5
#
# env: EVAL_PROJECT   UI project each "arrow" prompt runs against (prompts name its files;
#                     default: the arrow-escape repo these prompts were written for)
#      EVAL_OUT       where runs land (default: $TMPDIR/taste-eval)
#      EVAL_PARALLEL  concurrent sessions (default 4)
#      EVAL_ONLY      regex of prompt ids to run, e.g. "P5|P8" (default: all)
#
# Safety: every run is a throwaway copy without .git or wrangler.jsonc, under deny rules for
# deploys, pushes, installs, rm and curl - runs use --permission-mode bypassPermissions.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LABEL="${1:?label}"; MODE="${2:?installed|repo}"; shift 2
MODELS=("$@"); [ ${#MODELS[@]} -gt 0 ] || MODELS=(claude-sonnet-5 claude-opus-5-5)
export EVAL_PROJECT="${EVAL_PROJECT:-$HOME/Desktop/impark/furkansal/kutie-games/arrow-escape}"
export EVAL_OUT="${EVAL_OUT:-${TMPDIR:-/tmp}/taste-eval}"
mkdir -p "$EVAL_OUT"

DENY='"Bash(wrangler:*)","Bash(npx wrangler:*)","Bash(npm run deploy:*)","Bash(git push:*)","Bash(gh:*)","Bash(npm install:*)","Bash(npm i:*)","Bash(npm ci:*)","Bash(npm uninstall:*)","Bash(pnpm:*)","Bash(rm:*)","Bash(curl:*)"'
echo "{\"permissions\":{\"deny\":[$DENY]}}" > "$EVAL_OUT/settings-installed.json"
echo "{\"permissions\":{\"deny\":[$DENY]},\"enabledPlugins\":{\"taste-detector@taste-detector\":false}}" > "$EVAL_OUT/settings-repo.json"

one() {  # one <model> <promptId>
  local model=$1 pid=$2 prompt kind R
  prompt=$(awk -F'\t' -v p="$pid" '$1==p{print $3}' "$HERE/prompts.tsv")
  kind=$(awk -F'\t' -v p="$pid" '$1==p{print $2}' "$HERE/prompts.tsv")
  R="$EVAL_OUT/runs/$LABEL/$model/$pid"; rm -rf "$R"; mkdir -p "$R/proj"
  if [ "$kind" = arrow ]; then
    rsync -a --exclude node_modules --exclude .next --exclude .git --exclude wrangler.jsonc \
      --exclude tsconfig.tsbuildinfo "$EVAL_PROJECT/" "$R/proj/"
    [ -d "$EVAL_PROJECT/node_modules" ] && ln -s "$EVAL_PROJECT/node_modules" "$R/proj/node_modules"
  fi
  local extra=()
  [ "$MODE" = repo ] && extra=(--plugin-dir "$ROOT")
  (cd "$R/proj" && claude -p --model "$model" --max-turns 20 --permission-mode bypassPermissions \
    --settings "$EVAL_OUT/settings-$MODE.json" ${extra[@]+"${extra[@]}"} \
    --output-format stream-json --verbose "$prompt" > "$R/stream.jsonl" 2> "$R/stderr.txt") || true
  echo "$LABEL $model $pid done"
}
export -f one; export HERE ROOT LABEL MODE

for m in "${MODELS[@]}"; do cut -f1 "$HERE/prompts.tsv" | grep -E "^(${EVAL_ONLY:-.*})$" | sed "s/^/$m /"; done \
  | xargs -P "${EVAL_PARALLEL:-4}" -L 1 bash -c 'one "$0" "$1"'
python3 "$HERE/score.py" "$LABEL"
