# First UI edit in a project without impeccable's auto-check

The nudge hook sends you here on the first UI edit of a session, in a project where impeccable's own auto-check isn't wired and the taste gate is undecided. The goal: the user answers once, and on yes **the change you just made** gets the full check — not only the edits after it.

The nudge message carries the absolute paths used below. Reached from the skill instead, the script is at `<agents-with-taste base directory>/../../hooks/wire-impeccable.sh`, and the detector is `~/.claude/skills/impeccable/scripts/impeccable`.

1. **Ask once** with the question tool: "impeccable's auto-check and Emil's motion rules aren't set up for <project> yet. Set them up now? It covers the change I just made." Options: **Yes (Recommended)** / **No, not in this project**.

2. **Yes:**
   1. Run `wire-impeccable.sh "<project dir>" <every UI file you changed this session>`. It links the global impeccable into the project, registers impeccable's two hooks in `.claude/settings.local.json`, gitignores both inside an existing git repo, then re-checks the files you passed with impeccable's detector. Claude Code may show a permission prompt for the settings file; that is expected. Relay the wiring lines to the user in one line, and leave version control as the user has it.
   2. Triage every finding the re-check printed the way impeccable's hook asks: fix it, suppress it through `impeccable hooks ignore-*` with a reason, or leave it standing — and say which.
   3. Load `taste-detector:agents-with-taste` and run its steps on that same change.

   Done when the script reported success and a re-check line covering every UI file changed this session, its findings are triaged, and the motion in that change traces to a guide rule. impeccable's hook fires from the next edit on, in this same chat, and a wired project is never asked again.

   If the script says impeccable isn't installed globally: tell the user the one-line install it printed, write `.agents-with-taste/state.local.json` = `{"status": "consented", "decidedAt": "<today>"}` (so the question isn't repeated while the project stays unwired), and still do step 3.

3. **No:** write `{"status": "declined", "decidedAt": "<today>"}` to `.agents-with-taste/state.local.json`, gitignore `/.agents-with-taste/`, and carry on without these rules. The hooks stay silent in this project from then on.

## Prove the wiring fires

When the user wants proof, or anything above looked off: add an obviously bad line to a UI file, e.g. in a `.css` file

```css
.hook-fire-test { background: linear-gradient(45deg, #ff00ff, #00ffff); -webkit-background-clip: text; color: transparent; }
```

and confirm impeccable's own message names the `gradient-text` rule with a file and line. Then remove the line and confirm its follow-up reports clean. No message at all → `jq empty .claude/settings.local.json` (malformed JSON silently disables the whole file) and check that `.claude/skills/impeccable/scripts/impeccable` resolves.
