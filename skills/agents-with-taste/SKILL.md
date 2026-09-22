---
name: agents-with-taste
description: Motion and feel for UI and games — how things animate, ease, spring, respond to touch, and feel juicy (web, React Native/Expo, Swift). Use when adding or changing an animation, transition, hover/press feedback, gesture, or game feel; when a UI feels off, laggy, flat, or dead; when a web app should feel native on a phone; or to name a motion effect. When impeccable runs a design pass, load this for every motion moment it picks.
---

# Agents with Taste

Emil Kowalski's motion and feel rules, shipped as ten guides beside this skill. You are the entry point: pick the guides that match the task, read them, then build to their rules.

**impeccable decides *where* motion belongs and *why*. These guides decide *how* it moves** — curve, duration, spring, interruption, exit.

## Steps

1. **Check the gate.** Read `.agents-with-taste/state.local.json` at the project root. Missing, `"new"`, or `"consented"` → continue. `"declined"` → work without these rules; if motion quality comes up, say once that `agents-with-taste` is available.
   - User says "no taste here" → write `{"status": "declined", "decidedAt": "<today>"}` and add `/.agents-with-taste/` to `.gitignore`.
   - User says "turn taste on here" → write `{"status": "consented", "decidedAt": "<today>"}`.

2. **Pick and read the guides.** Each lives at `<this skill's base directory>/../<guide>/SKILL.md`. Most tasks need one or two.

   | The task is about… | Read |
   |---|---|
   | building a new animation, transition, or micro-interaction (web) | `animate` — plus `animate/RECIPES.md` for a button press, dropdown, tooltip, modal, drawer, toast, accordion, stagger, tab indicator, scroll reveal, or drag-to-dismiss |
   | a component's feel: press/hover response, popovers, tooltips, choosing an easing or a duration | `emil-design-eng` — § The Animation Decision Framework |
   | gestures, drag, swipe, sheets, springs, momentum, interruptible motion, game feel and juice | `apple-design` |
   | a web app on a phone: tap highlight, sticky hover, 100vh, input zoom, safe areas, PWA, bottom sheets, carousels | `mobile-native` |
   | naming a motion effect from a vague description | `animation-vocabulary` |
   | where a UI could gain motion (read-only scan) | `find-animation-opportunities` |
   | auditing a codebase's existing motion (read-only plan) | `improve-animations` |
   | React Native / Expo motion | `animate-expo` — plus its `RECIPES.md` |
   | Swift code | `write-swift` |
   | the Sonner toast library | `ask-sonner` — plus its `API.md` |

   Done when every chosen guide has been read in full, before any motion code is written.

3. **Build to the guides.** Take each motion change's easing curve, duration, and interruption behaviour from a guide rule, not from habit. When the guides genuinely leave a call open (two curves both fit, no default spring), ask with the question tool — after checking `emil-design-eng`'s Decision Framework and `animate/RECIPES.md`, which settle most cases.

   Done when every motion change in the diff has a curve, a duration, and an interruption behaviour you can trace to a guide rule, and `prefers-reduced-motion` is honoured.

## With impeccable

impeccable leads the overall design pass — layout, colour, type, UX, accessibility — and picks which moments earn motion. Run step 3 on each moment it picks. One review per concern: impeccable critiques the design, the guides settle the motion.

To wire impeccable's own per-project auto-check, follow [reference/first-ui-edit.md](reference/first-ui-edit.md).

## Games

Game loops, canvas, and WebGL are UI here. Juice, hit feedback, and timing follow `apple-design`'s physical-motion principles and `animate`'s curve, duration, and interruption rules.

## Slash-only extras

Offer these by name when they fit; only the user can start them:

- `/taste-detector:review-animations` — strict critique of existing motion
- `/taste-detector:pick-ui-library` — Emil's curated library picks
- `/taste-detector:prototype` — several live variants behind a picker
