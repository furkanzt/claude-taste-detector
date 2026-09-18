# Wiring impeccable's own per-project hook

Read this when [SKILL.md](../SKILL.md)'s "Session-scoped setup suggestion" section sends you here
after the user says yes. This plugin's own nudge hook is already active globally the moment this
plugin is installed — nothing about that needs repeating per project. The only gap this file
closes is impeccable's own detector, which is separately maintained, self-updating, and inherently
project-scoped by its own design (never merge it into this plugin or edit its files).

Check first — don't blindly reinstall:

```bash
IMPECCABLE_BIN=$(command -v impeccable || echo "$HOME/.claude/skills/impeccable/scripts/impeccable")
"$IMPECCABLE_BIN" hooks status
```

If `state: enabled` but this project has no `.claude/settings.local.json`, the config flag is on
but nothing calls it — `hooks on` alone only flips that flag, it does not wire the actual Claude
Code hook unless impeccable is installed *locally* in this project (its own auto-repair can't
write a hook manifest against a global-only install). Fix:

```bash
npx impeccable install --project --providers=claude --yes
```

This writes `.claude/skills/impeccable/` (a project-local copy + a per-platform binary) and a real
`.claude/settings.local.json` with impeccable's own `PostToolUse[Edit|Write]` immediate check plus
a `Stop`-event deep pass — separate from and in addition to this plugin's own global hook, which
needs no entry in that file at all.

Gitignore the reinstallable parts:

```gitignore
/.claude/skills/impeccable/
/.claude/agents/impeccable-*.md
/.claude/settings.local.json
```

**Prove it fires, don't assume the JSON is correct because it parses.** Pick any real UI file in
this project and:

1. Add an obviously-bad line via Edit, e.g. in a `.css` file:
   `.hook-fire-test { background: linear-gradient(45deg, #ff00ff, #00ffff); -webkit-background-clip: text; color: transparent; }`
2. Confirm you see TWO messages: impeccable's own, naming the `gradient-text` rule with a
   file/line, AND this plugin's own nudge pointing at `emil-design-eng`/`apple-design` for that
   same finding (confirming the plugin's global hook picked it up correctly).
3. Remove that line via a second Edit. Confirm impeccable's follow-up says clean.

If impeccable's own message doesn't appear: run `jq empty .claude/settings.local.json` (malformed
JSON silently disables the whole file) and re-check the command paths use `${CLAUDE_PROJECT_DIR}`
correctly. If this plugin's own nudge doesn't appear at all — even on a project with no impeccable
install, where it should still show the generic message — the plugin itself likely isn't
installed/enabled; check with `/plugin` or re-run its own install.

Finally, don't write `.agents-with-taste/state.local.json`'s `status` field on your own inference
just because this setup ran — that's [SKILL.md](../SKILL.md)'s own separate gate, decided
separately (classify greenfield vs. already-shipped, ask via the question tool for an
already-shipped project). This file only ever writes `impeccableSetupDeclined`, never `status`.
