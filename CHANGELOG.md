# Changelog

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
