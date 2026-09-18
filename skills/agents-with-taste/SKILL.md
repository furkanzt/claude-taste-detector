---
name: agents-with-taste
description: Gates and routes to Emil Kowalski's design-engineering skill family (emil-design-eng, animate, animate-expo, apple-design, animation-vocabulary, ask-sonner, find-animation-opportunities, improve-animations, mobile-native, review-animations, pick-ui-library, prototype, write-swift) for animation, motion, component-craft, game-feel, React Native/Expo, Sonner toasts, mobile-native web feel, and Swift decisions. Use whenever creating or touching UI, animation, micro-interactions, transitions, game feel/juice, a React Native/Expo app, or Swift code in any project — web, canvas, game-loop, or native. On greenfield UI work this applies automatically. On an already-shipped/built frontend it asks once per project before applying, then remembers the answer. Defers general UX/IA, accessibility, layout, and full design audits to the impeccable skill; this skill owns animation, motion-craft, and native-platform taste specifically. Not for backend-only work.
---

# Agents with Taste

Routes to Emil Kowalski's design-engineering skill family: https://emilkowal.ski/ui/agents-with-taste (the philosophy) and https://github.com/emilkowalski/skill (the source, vendored into this plugin at commit `85e8e2363b713506e1d5b6e07a0eb2da66be1bc3` — the full `skills/` set; see `EMIL-KOWALSKI-LICENSE` at the plugin root for the original MIT license this vendoring is under). Sub-skills, all shipped alongside this one in the same plugin:

| Skill | Use for | Auto-invokes? |
|---|---|---|
| `emil-design-eng` | General component-craft and polish: buttons, popovers, tooltips, the invisible details | Yes |
| `animate` | Building a new animation/transition/micro-interaction from scratch (web) — picks curve, duration, properties | Yes |
| `animate-expo` | Same decisions as `animate`, for React Native/Expo — which thread, Reanimated/Gesture Handler, spring vs. timing, gesture handoff, degradation on device | Yes |
| `apple-design` | Gesture-driven UI, spring physics, drag/swipe/sheets, momentum, interruptible transitions | Yes |
| `animation-vocabulary` | Turning a vague description ("the bouncy popover thing") into the exact term | Yes |
| `ask-sonner` | Installing, styling, theming, and troubleshooting the Sonner React toast library specifically | Yes |
| `find-animation-opportunities` | Read-only scan of a UI for places that would genuinely benefit from motion | Yes |
| `improve-animations` | Read-only audit of a codebase's existing motion, produces a prioritized plan | Yes |
| `mobile-native` | Making a *web* app feel native on a phone — sticky-hover, tap-highlight flash, 100vh, input zoom, safe-area, PWA/bottom-sheet/carousel specifics | Yes |
| `write-swift` | Writing/reviewing/migrating Swift: value types, Swift 6 concurrency, protocols/generics, ARC, Swift Testing, macros | Yes |
| `review-animations` | Strict critique of existing animation/motion code against Emil's bar | **No** — explicit-invocation only |
| `pick-ui-library` | Picking a UI library (OTP inputs, charts, virtualization, toasts, …) from Emil's curated list | **No** — explicit-invocation only |
| `prototype` | Building several genuinely different versions of a UI piece behind a live picker | **No** — explicit-invocation only |

The three marked "No" carry `disable-model-invocation: true` by Emil's own design — never assume or silently run them. Name them to the user as available commands instead (e.g. "I can also run `review-animations` on this if you want a strict pass").

**Web vs. native routing is already self-contained in each skill's own description** — `animate` says "for React Native use animate-expo," `animate-expo` says "for web animation use animate," `mobile-native` says "for motion itself use animate; for React Native use animate-expo." Don't re-derive this routing here; trust the individual skill descriptions to disambiguate by project type (a `.tsx`/`.css` web project vs. an Expo/React Native app vs. a `.swift` file) the same way `emil-design-eng` vs. `apple-design` already disambiguate by concern.

## Relationship to impeccable

Both skills touch frontend work; they don't overlap in practice if you route by what the request is actually about:

- **impeccable** owns: UX/information architecture, accessibility, responsive/layout behavior, theming, i18n, anti-patterns, full design-system audits and critique — a mature, versioned, self-updating skill, separately installed and maintained. Never merge this plugin with it or edit its own files; treat it as a black box you configure, not a codebase you patch.
- **This family** owns: animation/motion decisions (should it animate, which curve, what duration, spring config, interruptibility), component-craft micro-details, motion vocabulary, native-platform (Expo/Swift) taste, and Apple-style physical-motion principles.

A request about layout, hierarchy, contrast, or an overall design pass → impeccable. A request about whether something animates right, feels right, or moves well → this family. If a task spans both (e.g. "redesign this settings page"), let impeccable lead the overall pass and pull in `animate`/`emil-design-eng` for the motion pieces specifically — don't run a full impeccable critique and a full emil-design-eng review on the same diff for the same concern.

This plugin also ships a `PostToolUse[Edit|Write]` hook (`hooks/taste-nudge.sh`, registered globally by this plugin's own `hooks/hooks.json` — active in every project the moment this plugin is installed, no per-project setup) that runs impeccable's own detector directly on the just-edited file, when impeccable happens to be available for that project, and turns whatever it finds into a nudge toward the right skill in this family (a motion/easing finding points at `animate`/`review-animations`; any other visual finding points at `emil-design-eng`/`apple-design`). It degrades silently to a generic reminder if impeccable isn't installed for that project at all — it never requires impeccable, it just gets more specific when impeccable is there. See `reference/impeccable-setup.md` for the one remaining per-project step this doesn't automate (impeccable's own detector still needs its own project-local install to have anything to report).

## The gate: automatic vs. ask-first

Before applying any skill in this family, check this project's gate state at `.agents-with-taste/state.local.json` (project root, next to `.impeccable/` if present):

```json
{ "status": "new" | "consented" | "declined", "decidedAt": "<ISO date>" }
```

1. **State file exists** → follow it, don't ask again:
   - `"new"` or `"consented"` → apply automatically.
   - `"declined"` → don't apply. If directly relevant, you may mention once per session that it's available — don't repeat it every turn.
2. **No state file** (first time this family is relevant in this project) → classify the project:
   - **Greenfield** — no existing shipped UI yet, or the user is explicitly starting a new surface/page/game/component from scratch → apply automatically now, then write `{"status": "new", "decidedAt": "<today>"}`. Ensure `.agents-with-taste/` is covered by the project's `.gitignore` (add a line if it isn't — this file is machine-local state, same as `.impeccable/config.local.json`).
   - **Already built** — the project has existing, previously-shipped frontend/game code you'd be editing (not creating from nothing) → don't apply yet. Ask via the question tool, once:
     - "Yes, and remember for this project" → write `{"status": "consented", ...}`.
     - "Yes, just this session" → apply now, do **not** write the state file (so it asks again next session).
     - "No" → write `{"status": "declined", ...}`.

Never ask more than once per project per answer path (a "just this session" answer is expected to ask again later — that's what the user chose).

## Session-scoped setup suggestion: impeccable's own per-project hook

A separate question from the gate above: the gate decides whether this family's rules should
*apply* here; this decides whether impeccable's own detector — the thing that makes this plugin's
hook specific instead of generic — is wired for this particular project. This plugin's own hook is
already active everywhere the instant the plugin is installed; nothing about that is per-project.
The only remaining per-project gap is impeccable's own install, which stays outside this plugin's
scope by design (impeccable is separately maintained and self-updating).

Same shape as the `agenting` skill's own suggestion axis: a session-scoped flag, reset every
session, asked at most once per session regardless of how many times it would otherwise apply.

The first time in a session this family's rules become relevant to a task, check whether
impeccable is wired for the current project:

```bash
IMPECCABLE_BIN="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/impeccable/scripts/impeccable"
[ -x "$IMPECCABLE_BIN" ] && [ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/settings.local.json" ] && jq -e '[.hooks.PostToolUse[]?.hooks[]?.command] | any(test("impeccable"))' "${CLAUDE_PROJECT_DIR:-.}/.claude/settings.local.json" >/dev/null 2>&1
```

- **Exit 0 (impeccable wired here)** → say nothing about setup, proceed with the gate above as
  normal. This plugin's own hook will already be getting impeccable's real findings.
- **Non-zero (impeccable missing or not project-local)** → first check
  `.agents-with-taste/state.local.json` for `"impeccableSetupDeclined": true` — if set, this
  project already said no permanently; don't ask, proceed on this family's rules alone (the
  plugin's hook will fall back to its generic message, which is fine). Otherwise, ask once via the
  question tool:

  > "impeccable isn't wired for this project yet, so the design-taste nudge this plugin ships will
  > stay generic instead of pointing at specific findings. Want to set up impeccable's own
  > per-project hook now?"

  - **Yes** → follow [reference/impeccable-setup.md](reference/impeccable-setup.md), then continue
    the original task.
  - **No, just this session** → proceed without it, as if this section didn't exist; don't ask
    again this session, but do ask again next session (a session-only "no" is expected to be
    re-offered later — that's what makes it session-scoped rather than a permanent decline).
  - **No, don't ask again for this project** → write (or merge into)
    `.agents-with-taste/state.local.json` with `"impeccableSetupDeclined": true` alongside whatever
    `status` it already has, so future sessions skip the question entirely, not just this one.

This is orthogonal to the gate above: a project can have this family's rules consented but no
impeccable install (rules apply, hook stays generic), or impeccable wired with the gate declined
(hook gets specific findings but this family's own rules don't auto-apply). Don't conflate the two.

## Decisions during application

When applying these rules produces a genuine judgment call — two curves that both fit, a spring config with no obvious default, an animate-or-not call the framework doesn't resolve — ask via the question tool immediately rather than guessing or picking silently. Most calls are *not* judgment calls: check `emil-design-eng`'s Easing Decision Flowchart and Duration Guidelines and `animate/RECIPES.md` first — they resolve the large majority of cases outright, and re-asking something the rules already answer defeats the point of having them.

## Games and non-web UI

"Frontend work" for this gate includes game feel — any project with a game loop, canvas, or WebGL surface. Motion, juice, and interaction timing in a game are the same taste category as web animation: `apple-design`'s physical-motion principles and `animate`'s curve/duration/interruptibility framework translate directly to canvas/WebGL/game-loop timing, not just CSS. Apply the same gate.
