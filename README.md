# taste-detector

Emil Kowalski's design-engineering rules for **motion and feel** — how UI and games animate, ease,
spring, respond to touch, and feel juicy — wired to work alongside
[impeccable](https://impeccable.style/). impeccable decides *where* motion belongs and *why*; this
plugin's guides decide *how* it moves.

## How it routes

```
session start ── hooks/session-pointer.sh ── one pointer line in UI/game repos and empty folders
                                              ("motion/feel/juice → load agents-with-taste")
      │
      ▼
agents-with-taste  (the only taste skill on Claude's menu)
      │  reads the matching guide file(s) directly — no second Skill() hop
      ▼
animate · emil-design-eng · apple-design · mobile-native · animation-vocabulary · …
      ▲
first UI edit ── hooks/taste-nudge.sh ── runs impeccable's detector on the file, names the guide
                                         that fits; in an unwired project, starts the one-question
                                         setup (reference/first-ui-edit.md)
```

Hooks only inject context; loading the skill stays Claude's call each time. The pointer and the
nudge make that call's prompt deterministic instead of relying on a skill description out-matching
impeccable's on the menu.

## What's in it

- **`agents-with-taste`** — the router. The only model-invoked skill in the plugin: it checks the
  per-project gate, picks the guide(s) for the task, reads them, and builds to their rules.
- **13 guides**, vendored from [emilkowalski/skill](https://github.com/emilkowalski/skill) at
  commit `85e8e2363b713506e1d5b6e07a0eb2da66be1bc3` (MIT, see `EMIL-KOWALSKI-LICENSE`):
  - read by the router: `emil-design-eng`, `animate`, `animate-expo`, `apple-design`,
    `animation-vocabulary`, `ask-sonner`, `find-animation-opportunities`, `improve-animations`,
    `mobile-native`, `write-swift`
  - slash-only by Emil's own design: `review-animations`, `pick-ui-library`, `prototype`

  Every guide stays typeable as `/taste-detector:<guide>`.
- **`hooks/session-pointer.sh`** (SessionStart) — the pointer line above. Silent in backend-only
  repos and wherever the gate says `declined`.
- **`hooks/taste-nudge.sh`** (PostToolUse on Edit/Write, once per session) — runs impeccable's
  detector on the first UI file edited (project-local copy → this machine's global install → PATH)
  and names the guide that fits the finding.
- **`hooks/wire-impeccable.sh`** — wires impeccable's own per-project auto-check by symlinking the
  global install and registering the exact hook commands impeccable's installer writes. No
  download, no 14 MB copy in the repo, idempotent. Run by Claude after the user says yes in the
  first-edit flow, or by hand: `hooks/wire-impeccable.sh <project-dir>`.

## The per-project gate

Taste is **on by default**. `.agents-with-taste/state.local.json` (gitignored, machine-local) only
matters when it says `"declined"` — then both hooks go silent in that repo. Say "no taste here" to
write it, "turn taste on here" to reverse it.

In a project where impeccable's auto-check isn't wired and no answer is recorded yet, the first UI
edit triggers a single question. Yes → wire impeccable, then re-check *that same change* and apply
the guides to it. No → `declined`, never asked again there.

## Install

```
/plugin marketplace add furkanzt/claude-taste-detector
/plugin install taste-detector@taste-detector
```

impeccable itself is installed once per machine, separately (`npx impeccable install --user`).
This plugin never forks, vendors, or patches it; it only registers impeccable's own hook command
in a project, on consent.

## Maintaining

**Relationship to impeccable.** impeccable owns layout, colour, type, UX/IA, accessibility and
design audits; this plugin owns motion and feel. Treat impeccable as a black box you configure —
never merge it into this plugin or edit its files.

**Local change to the vendored guides.** The 10 router-read guides carry one added frontmatter
line, `disable-model-invocation: true`, so they stay off Claude's skill menu (about 1.6k tokens a
session) and are reached through the router. When re-vendoring a newer commit of Emil's skills,
re-apply that line to the same 10 and re-diff by hand — the pinned commit makes each update a
deliberate, reviewed pull. The GitHub archive for a pinned commit extracts to `skills-<sha>`, not
`skill-<sha>`; glob for it.

**Releasing.** Bump `version` in `.claude-plugin/plugin.json`, add a `CHANGELOG.md` entry, commit,
push. Everyone with the marketplace added picks it up on their next Claude Code startup.

**Tests.** `tests/hooks.test.sh` pipe-tests all three hook scripts against throwaway fixtures.
`tests/eval/run.sh <label> <installed|repo> [model …]` is the routing eval. It runs the prompts in
`tests/eval/prompts.tsv` headlessly against throwaway copies of a UI project, then scores whether
Claude reached `agents-with-taste`, the right guide, and impeccable, and whether it stayed quiet on
the negative controls. `repo` loads this working tree in place of the installed plugin, so a change
can be proven before it ships. Heavy prompts cost roughly $2–5 each on Opus; `EVAL_ONLY="P2|P5"`
re-runs just the ones you touched. Headless sessions have no question tool, so the first-edit
*question* can only be checked live; P9 answers "yes" inside its prompt to test the wiring path.

## Relationship to `claude-agenting`

Separate concern, separate repo, on purpose — [`claude-agenting`](https://github.com/furkanzt/claude-agenting)
governs subagent model/effort routing and workflow cost; this one governs design taste. Neither
depends on the other.

## License

MIT — see `LICENSE`. That covers this repo's own original content: the `agents-with-taste` skill
and the `hooks/` and `tests/` directories. It does not cover the vendored
`skills/{emil-design-eng,animate,animate-expo,apple-design,animation-vocabulary,ask-sonner,
find-animation-opportunities,improve-animations,mobile-native,pick-ui-library,prototype,
review-animations,write-swift}/` directories, which are Emil Kowalski's own work — also MIT, under
his own copyright; see `EMIL-KOWALSKI-LICENSE`. They are vendored unmodified except for the one
frontmatter line described under *Maintaining*.
