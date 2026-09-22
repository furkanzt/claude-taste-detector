#!/bin/bash
# Wires impeccable's own per-project auto-check - its PostToolUse immediate check and Stop deep
# pass - without `impeccable install --project`, which downloads a bundle (and can time out) and
# drops a 14 MB copy into the repo. Instead it symlinks this machine's global impeccable into the
# project and registers the exact hook commands impeccable's installer writes, so impeccable's own
# `doctor` sees the manifest it expects. Idempotent; prints one line per change it made.
#
# usage: wire-impeccable.sh [project-dir]   (default: $CLAUDE_PROJECT_DIR, then $PWD)
set -euo pipefail

P="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"
G="$HOME/.claude/skills/impeccable"

if [ ! -x "$G/scripts/impeccable" ]; then
  echo "impeccable isn't installed globally at $G - nothing wired. Install it once with: npx impeccable install --user"
  exit 1
fi

mkdir -p "$P/.claude/skills"
if [ -e "$P/.claude/skills/impeccable" ]; then
  echo "kept existing .claude/skills/impeccable"
else
  ln -s "$G" "$P/.claude/skills/impeccable"
  echo "linked .claude/skills/impeccable -> $G"
fi

python3 - "$P/.claude/settings.local.json" <<'PY'
import json, os, sys

path = sys.argv[1]
cmd = ('[ ! -f "${CLAUDE_PROJECT_DIR}/.claude/skills/impeccable/scripts/impeccable" ] || '
       '"${CLAUDE_PROJECT_DIR}/.claude/skills/impeccable/scripts/impeccable" hook')
wanted = {
    "PostToolUse": {"matcher": "Edit|Write",
                    "hooks": [{"type": "command", "command": cmd, "timeout": 5,
                               "statusMessage": "Checking UI changes"}]},
    "Stop": {"hooks": [{"type": "command", "command": cmd, "timeout": 30,
                        "statusMessage": "Design deep pass"}]},
}
settings = json.load(open(path)) if os.path.exists(path) else {}
hooks = settings.setdefault("hooks", {})
added = []
for event, entry in wanted.items():
    groups = hooks.setdefault(event, [])
    if not any(h.get("command") == cmd for g in groups for h in g.get("hooks", [])):
        groups.append(entry)
        added.append(event)
if added:
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print(f"registered impeccable's {' + '.join(added)} hook in .claude/settings.local.json")
else:
    print("impeccable's hooks already registered")
PY

if git -C "$P" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for rel in .claude/skills/impeccable .claude/settings.local.json; do
    if ! git -C "$P" check-ignore -q "$rel"; then
      printf '/%s\n' "$rel" >> "$P/.gitignore"
      echo "gitignored /$rel"
    fi
  done
fi
