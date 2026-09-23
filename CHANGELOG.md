# Changelog

## 1.1.0 — 2026-09-22

Restructured so the family actually fires. In the four days after 1.0.0, three real nudges led
to one skill load, and the router's second hop could fail.

- **Fixed: the router named sub-skills by bare name** (`emil-design-eng`, `animate`, …).
  With same-named user-level copies switched off in `skillOverrides`, a bare-name call failed
  with "Skill emil-design-eng is disabled for model invocation". In practice Claude usually used
  the full listed name instead. The router now reads each guide's `SKILL.md` by path, so there is
  no second `Skill()` call left to fail.
- **One entry point.** `agents-with-taste` is the only model-invoked skill; the 10 guides it
  routes to carry `disable-model-invocation: true` (a one-line local change to the vendored
  files, documented in the README) and stay typeable as `/taste-detector:<guide>`. About 1.6k
  tokens a session come off the skill menu, along with ten descriptions that competed with
  impeccable's.
- **Router rewritten** trigger-first around *motion / feel / juice*, with a routing table,
  completion criteria, and the impeccable split stated as where/why vs. how. The description drops
  from 958 to 430 characters. Maintainer notes moved to the README.
- **New `SessionStart` pointer** (`hooks/session-pointer.sh`): one line in repos with UI code and
  in empty folders, silent in backend-only repos and where declined. An always-loaded pointer
  doesn't depend on a description winning the menu match.
- **Gate is on by default.** Only `"declined"` silences the plugin; the greenfield-vs-shipped
  question and the per-session impeccable-setup question are gone.
- **First UI edit in an unwired project** (`reference/first-ui-edit.md`, replacing
  `impeccable-setup.md`): the nudge scans the file with impeccable's detector and starts one
  question. On yes, Claude wires impeccable, then re-checks and applies the guides to *that same
  change*, not only later ones.
- **`hooks/wire-impeccable.sh`**: wires impeccable's own per-project auto-check by symlinking the
  global install and registering the exact hook commands its installer writes. `impeccable install
  --project` downloads a bundle (which timed out when tried) and copies 14 MB into the repo; the
  symlink needs neither. Idempotent, and it gitignores what it adds.
- **Nudge wording** is now finding-aware and names `taste-detector:agents-with-taste` instead of
  the unreachable bare guide names.
- **`tests/hooks.test.sh`**: 22 pipe tests over all three hook scripts, including a mutation-checked
  "no `.gitignore` outside git" case.
- **`tests/eval/`**: a headless routing eval. 1.0.0 → 1.1.0 moved Opus 5.5 from 6/8 to 7/8 and
  Sonnet 5 from 4/8 to 6/8. The new-project prompt went from FAIL to PASS on both models through
  the pointer alone. Fixes driven by the eval:
  - The router loads impeccable first when a request leaves open *which* moments should move
    (juicier, nicer, more polished) and skips it when the user already named the moment.
  - The pointer also covers "what's this effect called?". Sonnet still answers those from memory,
    and less accurately than the `animation-vocabulary` guide.
  - The first-edit flow writes `consented` only when wiring fails, because a wired project is
    never asked again anyway. `wire-impeccable.sh` now says so when a folder isn't a git repo,
    after one run `git init`-ed an empty folder to get the gitignore protection.
  - `wire-impeccable.sh` takes the UI files changed so far and re-checks them itself once
    wiring is done, so covering the first change no longer depends on Claude remembering a step.
    Under a strict P9 (edit → wire → re-check covering that edit), Sonnet 5 passes. Opus 5.5
    re-checked and applied taste but hadn't wired by the 20-turn cap. Headless runs have no
    question tool, so the ask → yes path itself needs a live check.

## 1.0.0 — 2026-09-18

Initial release, developed and verified against `arrow-escape` before this repo existed:

- Vendored all 13 skills from `emilkowalski/skill` at commit `85e8e2363b713506e1d5b6e07a0eb2da66be1bc3`.
- Wrote `agents-with-taste`, the router/gate skill tying them together and explaining the split
  from `impeccable`.
- Wrote `hooks/taste-nudge.sh` + `hooks/hooks.json`: a global `PostToolUse[Edit|Write]` hook that
  runs impeccable's own detector on the just-edited file and tailors a reminder to what it found.
  Two real bugs caught and fixed before this shipped:
  - `impeccable detect` exits 2 (not 0) on real findings — an early draft's
    `$(cmd 2>/dev/null || echo "[]")` treated that as failure, and since impeccable still prints
    its real JSON to stdout on exit 2, the `||` branch ran anyway and concatenated both outputs
    into something that failed JSON validation and silently discarded every finding. Fixed by
    moving `|| true` outside the substitution, so stdout is captured unconditionally regardless of
    exit code.
  - The GitHub archive for a pinned commit extracts to `skills-<sha>`, not `skill-<sha>` as the
    `emilkowalski/skill` URL slug would suggest — any vendoring script that hardcodes the expected
    directory name breaks; use a glob instead.
- Added the three-way impeccable lookup (project-local → this machine's global install → none) so
  the hook works correctly regardless of which of those is true for a given project, since it's
  now installed once per machine rather than hand-wired per project.
