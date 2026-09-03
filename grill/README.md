# /grill

An Agent Skills-standard skill for Claude Code and the Pi coding harness that does adversarial pre-commit review. Run it after Claude (or you) writes code, before it ships — it switches Claude from author to opposing counsel and cross-examines the change instead of admiring it.

## The problem

The agent that just wrote the code is the worst reviewer of it. It already believes the logic is correct, the inputs are handled, and the tests would pass — that's why it stopped writing. Ask "does this look right?" and you get agreement, not review.

The place this bites hardest: unattended automations. A scheduled job that swallows an exception and returns success doesn't fail loudly at 3am — it goes quiet, which looks exactly like "nothing to report."

## What /grill does

Treats the change as a witness making claims, none accepted without evidence:

1. **Establishes the record** — diffs against HEAD, reads every touched file in full, states the one-line claim on trial
2. For non-trivial diffs, **dispatches a fresh-eyes subagent** as opposing counsel when the harness has one (Claude Code does; Pi only with an installed subagent extension) — it gets the diff and the intent, not the author's reasoning from the writing session. Without one it grills inline after deliberately setting the author's reasoning aside
3. Cross-examines in six passes: logic correctness, hostile inputs, production reality (cold starts, silent external-call failures, env drift), dead code & secrets, whether the tests were actually run, and what's missing from the diff entirely
4. Every finding: `file:line`, the unsupported claim, why it doesn't hold up, what fixing it takes — rated 🔴 fails / 🟡 weak / 🟢 minor / ❓ insufficient evidence
5. Ends with a verdict: **SHIP** (hand off to `/ship`) or **DON'T SHIP** plus the controlling reason

## A worked example

```
you:    /grill
claude: Record: 1 file changed, +10 lines. Claim on trial: post the weekly
        average to the status webhook.

  🔴 stats.py:10 — `except Exception: pass` then `return True`: every failure
     of the webhook post reports as success. In an unattended job, silence IS
     the failure mode.
  🔴 stats.py:7 — weekly_average([]) → ZeroDivisionError, outside the try.
     The empty week isn't "never happens" — it's a holiday.
  🟡 stats.py:1 — `requests` isn't declared anywhere; a cold CI runner gets
     ImportError.
  Conceded: happy-path math is right; timeout=5 is present.

  Verdict: DON'T SHIP — the error handling inverts reality. Fix the failure
  handling, then re-grill Pass 3 only.
```

## What /grill will NOT do

- Fix the code — it reports; you decide what gets fixed
- Commit, push, or deploy — that's `/ship`, after a SHIP verdict
- Invent objections to look thorough — well-supported claims get conceded in one line
- Rubber-stamp — "looks right" is not evidence, and it won't pretend it is

## Install

One checkout serves both harnesses. Claude Code discovers skills in `~/.claude/skills/<name>`; Pi discovers them in `~/.agents/skills/<name>`. The bundled script links this directory into both:

```bash
scripts/install-skill-links.sh --dry-run   # preview
scripts/install-skill-links.sh --yes       # apply (add --force to repoint a link to another checkout)
```

Then start a new session (skills load at session start) and run `/grill` in Claude Code or `/skill:grill` in Pi after writing code, before committing. Both load the same `SKILL.md`.

### Dependencies

- **`git`** (required)
- A change worth cross-examining

## Customization

Natural-language overrides — no flags needed:

| You say | Claude does |
|---|---|
| "grill this inline" | Skips the fresh-eyes subagent, reviews in-session (the only mode on a harness without a subagent tool) |
| "grill just the error handling" | Runs only the relevant pass |
| "quick grill" | Passes 1–3 only (logic, inputs, production) |

## Design notes (for anyone modifying)

- **The courtroom framing is load-bearing.** "Burden of proof is on the code" produces materially different review behavior than "check for bugs" — the default agent posture is to confirm, not contest.
- **The fresh-eyes subagent exists because prose can't fully undo author bias.** An agent that wrote the code in-session already believes its claims; a subagent that only sees the diff and the intent doesn't.
- **Frivolous objections are treated as a defect**, not thoroughness. A review that flags everything flags nothing.

Source of truth: `SKILL.md` in this directory. The YAML frontmatter (`description`) controls when either harness invokes the skill — keep it trigger-only (symptoms and situations, not workflow), or agents will perform the description instead of reading the skill.

## Pairs well with /ship and /wrap-up (optional)

`/grill` → `/ship` → `/wrap-up` is the intended loop (`/skill:grill` → `/skill:ship` → `/skill:wrap-up` in Pi): cross-examine the change, commit/push/PR it, then close out the session. Each skill works standalone; none requires the others.

## Feedback

This is v1. Expect to tune it. Edits to `SKILL.md` take effect next session.
