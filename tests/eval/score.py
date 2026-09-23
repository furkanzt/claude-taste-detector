#!/usr/bin/env python3
"""Score taste-detector eval runs: did Claude route to the right skill/guide?

usage: score.py <label> [<label> ...]   (reads $EVAL_OUT/runs/<label>/<model>/<promptId>/)
"""
import glob, json, os, re, sys

E = os.environ.get("EVAL_OUT") or os.path.join(os.environ.get("TMPDIR", "/tmp"), "taste-eval")
GUIDES = ["emil-design-eng", "animate-expo", "animate", "apple-design", "animation-vocabulary",
          "ask-sonner", "find-animation-opportunities", "improve-animations", "mobile-native",
          "write-swift", "review-animations", "pick-ui-library", "prototype"]
GUIDE_RE = re.compile(r"/(" + "|".join(GUIDES) + r")/[^/]*\.md$")
EXPECT = {  # (must load taste?, acceptable guides or None, needs impeccable?)
    "P1": (True, {"animate", "apple-design"}, False),
    "P2": (True, None, True),
    "P3": (True, {"emil-design-eng", "animate"}, False),
    "P4": (True, {"mobile-native"}, False),
    "P5": (True, {"animation-vocabulary"}, False),
    "P6": (False, None, False),
    "P7": (False, None, False),
    "P8": (True, None, False),
    "P9": (True, None, False),  # simulated "yes": UI edit -> wire -> re-check covering that edit
}


def transcript_for(run):
    sid = None
    try:
        for line in open(os.path.join(run, "stream.jsonl")):
            d = json.loads(line)
            if d.get("session_id"):
                sid = d["session_id"]; break
    except Exception:
        return None, None
    hits = glob.glob(os.path.expanduser(f"~/.claude/projects/*/{sid}.jsonl")) if sid else []
    return (hits[0] if hits else None), sid


def analyse(run):
    path, sid = transcript_for(run)
    m = {"events": [], "taste": False, "guides": set(), "impeccable": False, "asked": False,
         "pointer": False, "nudge": False, "turns": 0, "cost": None, "final": ""}
    for line in open(os.path.join(run, "stream.jsonl")):
        try: d = json.loads(line)
        except Exception: continue
        if d.get("type") == "result":
            m["cost"] = d.get("total_cost_usd"); m["turns"] = d.get("num_turns", 0)
            m["final"] = (d.get("result") or "")[:200]
    proj = os.path.join(run, "proj")
    try: m["wired"] = "skills/impeccable/scripts/impeccable" in open(os.path.join(proj, ".claude/settings.local.json")).read()
    except OSError: m["wired"] = False
    try: m["consented"] = json.load(open(os.path.join(proj, ".agents-with-taste/state.local.json"))).get("status") == "consented"
    except (OSError, ValueError): m["consented"] = False
    if not path:
        m["missing"] = True
        return m
    for line in open(path, errors="ignore"):
        try: d = json.loads(line)
        except Exception: continue
        a = d.get("attachment") or {}
        blob = json.dumps(a) if a else ""
        if "agents-with-taste" in blob or "taste-detector" in blob:
            hn = a.get("hookName", "")
            if hn.startswith("SessionStart"): m["pointer"] = True
            if hn.startswith("PostToolUse"): m["nudge"] = True
        c = d.get("message", {}).get("content") if isinstance(d.get("message"), dict) else None
        if not isinstance(c, list): continue
        for x in c:
            if x.get("type") != "tool_use": continue
            n, inp = x.get("name"), x.get("input", {})
            cmd = inp.get("command") or ""
            if n in ("Write", "Edit") and re.search(r"\.(html|css|tsx|jsx|vue|svelte)$", inp.get("file_path", "")):
                m["events"].append("EDIT")
            elif n == "Bash" and "wire-impeccable.sh" in cmd and not re.match(r"\s*(cat|sed|head|less|rtk read)\b", cmd):
                m["events"].append("WIRE+FILES" if re.search(r"wire-impeccable\.sh\S*\s+\S+\s+\S+\.(html|css|tsx|jsx|vue|svelte)", cmd) else "WIRE")
            elif n == "Bash" and "impeccable" in cmd and " detect" in cmd:
                m["events"].append("DETECT")
            if n == "Skill":
                s = inp.get("skill", "")
                base = s.split(":")[-1]
                if base == "agents-with-taste": m["taste"] = True
                if base in GUIDES: m["guides"].add(base); m["taste"] = True
                if base == "impeccable": m["impeccable"] = True
            elif n in ("Read", "Bash", "Grep", "Glob"):
                t = inp.get("file_path") or inp.get("command") or inp.get("path") or ""
                if "agents-with-taste/SKILL.md" in t: m["taste"] = True
                for g in GUIDES:
                    if re.search(r"/" + re.escape(g) + r"/[A-Za-z_.-]*\.md", t):
                        m["guides"].add(g); m["taste"] = True
                if n == "Bash" and "impeccable" in t and "scripts/impeccable" in t: m["impeccable"] = True
            elif n == "AskUserQuestion":
                m["asked"] = True
    return m


def verdict(pid, m):
    need_taste, ok_guides, need_imp = EXPECT[pid]
    if m.get("missing"): return "NO-TRANSCRIPT"
    if not need_taste:
        return "PASS" if not m["taste"] else "FAIL(over-fired)"
    if pid == "P8":
        return "PASS" if (m["taste"] or m["asked"]) else "FAIL"
    if pid == "P9":
        ev = m["events"]; missing = [k for k in ("taste", "wired") if not m.get(k)]
        wire_at = next((i for i, e in enumerate(ev) if e.startswith("WIRE")), None)
        if wire_at is None or "EDIT" not in ev[:wire_at]: missing.append("edit-before-wire")
        elif not (ev[wire_at] == "WIRE+FILES" or "DETECT" in ev[wire_at:]): missing.append("recheck-after-wire")
        return "PASS" if not missing else "FAIL(no " + ",".join(missing) + ")"
    if not m["taste"]: return "FAIL(no taste)"
    if ok_guides and not (m["guides"] & ok_guides): return "PART(wrong/no guide)"
    if need_imp and not m["impeccable"]: return "PART(no impeccable)"
    return "PASS"


for label in sys.argv[1:]:
    print(f"\n=== {label}")
    for model_dir in sorted(glob.glob(os.path.join(E, "runs", label, "*"))):
        model = os.path.basename(model_dir); passes = 0; total = 0
        for pid in sorted(EXPECT):
            run = os.path.join(model_dir, pid)
            if not os.path.exists(os.path.join(run, "stream.jsonl")): continue
            m = analyse(run); v = verdict(pid, m); total += 1; passes += v == "PASS"
            print(f"{model:16s} {pid} {v:22s} taste={int(m['taste'])} guides={','.join(sorted(m['guides'])) or '-':32s} "
                  f"imp={int(m['impeccable'])} ask={int(m['asked'])} ptr={int(m['pointer'])} nudge={int(m['nudge'])} "
                  f"turns={m['turns']} ${m['cost'] or 0:.2f}" + (f" seq={'>'.join(m['events'])}" if pid == "P9" else ""))
        print(f"{model:16s} SCORE {passes}/{total}")
