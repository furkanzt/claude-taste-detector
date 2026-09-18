# taste-detector

Emil Kowalski's design-engineering skill family, vendored and auto-invoking, plus a global hook
that runs [impeccable](https://impeccable.style/)'s own detector on every UI edit and turns
whatever it finds into a nudge toward the right skill in the family — a motion/easing finding
points at `animate`/`review-animations`, any other visual finding points at
`emil-design-eng`/`apple-design`, and it degrades to a generic reminder when impeccable isn't set
up for that project at all. **The hook only ever injects a reminder into context — it never
invokes a skill by itself.** That call is still made by the model each time; this makes the
prompt to make that call deterministic instead of relying on memory.

## What's in it

- **13 skills**, vendored from [emilkowalski/skill](https://github.com/emilkowalski/skill) at
  commit `85e8e2363b713506e1d5b6e07a0eb2da66be1bc3` (MIT-licensed, see `EMIL-KOWALSKI-LICENSE`):
  `emil-design-eng`, `animate`, `animate-expo`, `apple-design`, `animation-vocabulary`,
  `ask-sonner`, `find-animation-opportunities`, `improve-animations`, `mobile-native`,
  `pick-ui-library`, `prototype`, `review-animations`, `write-swift`.
- **`agents-with-taste`**, the router/gate skill that ties them together, decides when they should
  auto-apply on an already-shipped project vs. a greenfield one, and explains how this family
  relates to `impeccable` (UX/IA/accessibility/audits) so the two don't overlap.
- **A global `PostToolUse[Edit|Write]` hook** (`hooks/hooks.json` + `hooks/taste-nudge.sh`) that's
  active in every project the instant this plugin is installed — no per-project setup for this
  part. It checks for `impeccable` three ways (this project's own local install, this machine's
  global install, then gives up gracefully) and reads its findings directly, not a cache, to avoid
  any assumption about hook execution order.

## Install

```
/plugin marketplace add furkanzt/claude-taste-detector
/plugin install taste-detector@taste-detector
```

That's it for the skills and the global hook — they apply to every project on this machine from
then on, and update automatically when this repo does.

## One thing this plugin does NOT automate

`impeccable` itself stays separately installed per project — it's a mature, versioned,
self-updating tool with its own lifecycle, and this plugin deliberately doesn't fork, vendor, or
patch it. Without it, this plugin's hook still fires and still reminds you toward the right skill
family, just without a specific finding to point at. `agents-with-taste/reference/impeccable-setup.md`
walks through wiring it for a given project (`npx impeccable install --project --providers=claude
--yes`), and the router skill itself will offer to walk you through it, once per session, the
first time a project without it becomes relevant.

## Relationship to `claude-agenting`

Separate concern, separate repo, on purpose — [`claude-agenting`](https://github.com/furkanzt/claude-agenting)
governs subagent model/effort routing and workflow cost, this one governs design taste. Install
either independently; neither depends on the other.

## Updating this plugin

Bump `version` in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, note
the change in `CHANGELOG.md`, commit, push. Everyone with the marketplace added picks it up
automatically on their next Claude Code startup — no re-install, no manual re-sync.

To bring in a newer commit of Emil's own skills, re-run the same vendoring process against the new
commit SHA and re-diff by hand before committing — this repo pins a specific commit deliberately,
so an update to the vendored content is a deliberate, reviewed pull, not something that happens on
its own.

## License

MIT — see `LICENSE`. That covers this repo's own original content: the `agents-with-taste` router
skill and the `hooks/` directory (`hooks.json`, `taste-nudge.sh`). It does not cover the vendored
`skills/{emil-design-eng,animate,animate-expo,apple-design,animation-vocabulary,ask-sonner,
find-animation-opportunities,improve-animations,mobile-native,pick-ui-library,prototype,
review-animations,write-swift}/` directories, which are Emil Kowalski's own work, vendored
unmodified from [emilkowalski/skill](https://github.com/emilkowalski/skill) — also MIT, but under
his own copyright; see `EMIL-KOWALSKI-LICENSE`.
