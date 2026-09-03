---
name: grill
description: Use after writing or changing code, before commit or deploy — especially for unattended automations, scheduled jobs, or pipelines where a failure would be silent. Also triggered by /grill in Claude Code, /skill:grill in Pi, "grill this", or any request for an adversarial / hostile review of a change. Works from Claude Code or Pi.
compatibility: Requires git and a POSIX shell inside a git repository, plus the project's own test runner when a test run is demanded. No MCP. A subagent tool is optional (Claude Code has one; Pi only with a subagent extension installed); without one the review runs inline.
---

# grill

You just wrote this and you're ready to call it done. Not yet. Right now you're the author, convinced of your own case. Switch sides.

Become **opposing counsel** — a sharp devil's advocate whose job is to find where this falls apart. The code is a witness making claims: that the logic is correct, that it handles the inputs, that it works in production, that the tests pass. **You accept none of it without substantiation.** The burden of proof is on the code, not on you to disprove it. "Looks right" is not evidence. "Should work" is testimony, not proof.

## Harness portability

- One Agent Skills-standard workflow for both harnesses: `/grill` in Claude Code, `/skill:grill` in Pi, or invoked naturally. Everything below uses git, the shell, and the project's own test runner; no MCP or harness tool is required.
- A subagent tool is the one optional extra. Use it only if the harness lists one among your tools (Claude Code does; Pi only when a subagent extension is installed). Never fabricate a subagent call; the fresh-eyes paragraph below says what to do without one.
- Cross-skill references name the skill, not a slash command: `/ship` is the user-facing spelling (`/skill:ship` in Pi) of the ship skill that lives beside this one.
- Machine setup is `scripts/install-skill-links.sh` beside this file: `--dry-run` to preview, `--yes` to link this checkout into `~/.agents/skills/grill` (Pi) and `~/.claude/skills/grill` (Claude Code).

## First — enter the change into evidence

Before cross-examining, establish what's actually on trial:

- `git diff HEAD` and `git status --short` (on a feature branch reviewing cumulative work, diff from the merge-base instead). Untracked files are part of the change — read them.
- Read every touched file in full, not just the hunks — the diff shows what changed, not what the file now says; the surrounding code is where the contradictions hide.
- State the claim in one line: what is this change supposed to do? That's the case you're testing against.

**Fresh eyes beat willpower.** If you wrote this code in this session, you already believe its claims — the exact bias this skill exists to fight. For a non-trivial diff, dispatch a subagent as opposing counsel: give it only the diff, the touched file paths, and the one-line intent — none of your reasoning from the writing session — and have it run the passes below and return findings in the output format. Grill inline for small diffs, or when the harness has no subagent tool. Inline without fresh eyes, having written the code yourself, is the weakest seat in the room, so before Pass 1 re-read only the diff, the touched files, and the one-line claim, and cross-examine what is on the page rather than what you remember intending.

Cross-examine in passes. For every finding: `file:line`, the unsupported claim, why it doesn't hold up, and what it would take to fix.

## Pass 1 — The claim: "the logic is correct"
Don't grant it because it reads plausibly — that's exactly how wrong-but-plausible code gets through. Re-derive it from scratch. Trace a real input through by hand. Does it actually do what was asked, or does it merely *resemble* code that would? Where does the happy path quietly diverge from correct?

## Pass 2 — The claim: "it handles the inputs"
Substantiate it against the hostile ones. Nulls. Empty lists. Zero. The day with no data. The "never happens" state that happens. Any input you didn't test is an unsupported claim — treat it as unhandled until shown otherwise.

## Pass 3 — The claim: "it works in production" (the one that needs the most evidence)
"Works on my machine" is not evidence. Where production fails silently:
- Does anything assume local state survives between runs? CI runners, scheduled jobs, and cloud sandboxes start cold — gitignored DBs/caches start empty and clever incremental logic no-ops **without ever erroring.**
- Every external call — webhooks, third-party APIs, queues, KV/cache stores, the network — what's the evidence it fails LOUD rather than swallowing the error and looking like success? Silent success-on-failure is the enemy.
- Env drift: timezone, a missing env var, a rotated secret, an expired token.
- If this breaks at 3am unattended, what's the evidence we'd find out? If there's none, that's a finding.

## Pass 4 — Unsupported material in the record
Dead code: imports/vars/functions entered into evidence and never used. Copy-paste seams from whatever you adapted this from — find them. Off-by-ones. String concatenation that should be a template. Hardcoded values that should be config. **Secrets pasted into code or prompts.** Types that are `any` wearing a trenchcoat.

## Pass 5 — The claim: "the tests pass"
"Should still pass" is testimony, not evidence — produce the test run. Did you actually execute them, or assume? And do they exercise the claim, or just the happy path you already knew worked? Untested failure paths are unsupported.

**When the artifact is prose — a prompt, agent instructions, a config note — check what the test actually binds to.** A harness that reimplements the rule in code validates the reimplementation, not the thing that ships. The two disagree silently: the code can be right while the sentence the agent reads is wrong, and every test still passes. Read the instruction back literally, the way an indifferent reader would, and hunt the boolean seams — "outside X **and** outside Y" is not "outside the box"; "prefer A, fall back to B" hides whatever B actually contains. Then choose cases that can only be decided by the wording: **if every example you tried fails *both* halves of an AND, you have not tested the AND.**

## Pass 6 — What's missing from the record?
The case is built on what's *not* in the diff too: the doc update, the alert path, the rollback, the allowlist entry, the .gitignore line, the index a new file needs.

## Output (the verdict)
- 🔴 **Fails** — broken or will break. Fix before commit.
- 🟡 **Weak** — holds for now, but fragile / unsubstantiated / will be challenged later.
- 🟢 **Minor** — cosmetic. Note once, move on.
- ❓ **Insufficient evidence** — can't be confirmed without running it or more context. Say so; don't rule either way on a guess.

Rules:
- Go after the substantive claims — wrong-but-plausible logic and silent-failure paths — not easy cosmetic nits.
- Don't invent objections. If a claim is genuinely well-supported, concede it in one line and move on. A frivolous objection costs credibility.
- Demanding, not theatrical — a talented advocate, not a caricature. End with a verdict: **SHIP** or **DON'T SHIP**, plus the controlling reason if it's don't-ship.
- Verdict **SHIP** → hand off to the ship skill to commit and push (load `ship/SKILL.md` from the same skills directory and follow it; `/ship` in Claude Code, `/skill:ship` in Pi). **DON'T SHIP** → fix the controlling finding, then re-grill just that claim, not all six passes.
