---
name: wrap-up
description: Use at the end of a working session — triggered by /wrap-up in Claude Code, /skill:wrap-up in Pi, or "wrap up" / "let's close out" — for the once-per-session closeout that /ship skips. Not for individual commits (use /ship). Works from Claude Code or Pi.
compatibility: Requires git and a POSIX shell inside a git repository. No MCP or harness-specific tool. The ship skill (same skills directory) handles the final commit. Memory promotion writes to the Claude Code auto-memory store on this machine when the project already has one.
---

# Wrap-Up

End-of-session closeout. Does the expensive semantic work that `/ship` is deliberately too lightweight to cover.

## When to Use

- User invokes `/wrap-up` at end of working session
- Running once is the expected pattern — this skill is not meant to be invoked repeatedly
- For per-commit work (verification, commit, push, PR), use `/ship`

## Harness Portability

- One Agent Skills-standard workflow for both harnesses: `/wrap-up` in Claude Code, `/skill:wrap-up` in Pi, or invoked naturally. Everything below uses git, the shell, and files in the repo; no MCP or harness tool is required.
- Resolve paths from the directory containing this `SKILL.md` (follow the global symlink to its checkout); `references/` sits beside it.
- "Run in parallel" means: issue the commands concurrently if the harness runs sibling tool calls in parallel, otherwise one after another. Order never matters for those reads.
- Cross-skill references name the skill, not a slash command. "Invoke the ship skill" means load `ship/SKILL.md` from the same skills directory as this file and follow it; `/ship` (Claude Code) and `/skill:ship` (Pi) are only the user-facing spellings.
- Machine setup is `scripts/install-skill-links.sh` beside this file: `--dry-run` to preview, `--yes` to link this checkout into `~/.agents/skills/wrap-up` (Pi) and `~/.claude/skills/wrap-up` (Claude Code).

## What `/wrap-up` Will Not Do

- Edit code (beyond doc updates it explicitly proposes)
- Make architectural or product decisions
- Close issues or update Linear / Jira / Notion trackers
- Save anything to memory without your confirmation
- Run meaningfully if invoked repeatedly — this skill is once-per-session
- Retroactively verify or re-run tests (that was `/ship`'s job before each commit)

## What This Skill Owns (vs. /ship)

| Concern | `/ship` | `/wrap-up` |
|---|---|---|
| Commit + push | ✓ | delegates to `/ship` |
| Tests / lint / typecheck | ✓ | delegates to `/ship` |
| Targeted (diff-driven) doc staleness | ✓ | — |
| PR creation (feature branches) | ✓ | delegates to `/ship` |
| **Holistic doc review** | — | ✓ |
| **Session log + index update** | — | ✓ |
| **Promote durable learnings to memory** | — | ✓ |
| **Dirty-start detection** | — | ✓ |

## Workflow

### 1. Scope the session (with dirty-start check)

Identify the cumulative work done this session. Run in parallel:

- `git log --since="6 hours ago" --oneline` (adjust window if session was longer)
- `git diff <first-session-commit>^..HEAD --stat`
- `git status --short` (for uncommitted work)

Also review the conversation context — some changes may be investigation/decisions that didn't land in commits.

**Dirty-start check.** Uncommitted work may predate this session (a different agent's in-progress work, a WIP from another machine, a pending experiment you set aside). Before bundling it into the wrap-up:

- Compare mtimes of modified files against the session's first commit time (`stat -f %m <file>` on macOS, `stat -c %Y <file>` on Linux)
- If any files look older than the session, ask explicitly:
  > "I see N uncommitted files. Are these from this session, or leftover from before? `[this session / leftover / mixed — let me pick]`"
- Exclude leftover work from the doc review and session log unless the user says to include it
- If in doubt, ask — don't silently bundle unfamiliar work into a wrap-up commit

### 2. Holistic doc review

This is the step `/ship` deliberately skips. Read these files in full and compare against the session's cumulative changes:

- `README.md`
- `CLAUDE.md` (every CLAUDE.md in the repo, not just root)
- `ROADMAP.md` (if present)
- `docs/**/*.md` (scan filenames, read those whose topics overlap with the session's work)

For each doc, ask:

- Does it still accurately describe the project?
- Were ROADMAP items completed that should be checked off?
- Is any new behavior/feature undocumented?
- Are setup/install/usage instructions still correct?
- Does CLAUDE.md reference files/commands that moved or changed?

For each stale doc: show what's outdated, propose specific edits, apply after confirmation. Skip silently if nothing is stale.

### 3. Session file (if warranted)

Full conventions (directory structure, format, multi-day sessions) are in `references/session-management.md`; the essentials below stand on their own.

**Create a session file for:**
- New features or pages
- Non-trivial bug fixes (>1 file or non-obvious root cause)
- Architectural changes
- Multi-file refactors
- Complex investigations (even unresolved)

**Heuristic:** if the session's cumulative diff touched >3 files or >100 LOC, lean toward creating one.

**Skip for:**
- Typo fixes, single-line changes
- Pure Q&A with no code changes
- Sessions where all work is already well-described by commit messages

If creating a session file:
1. Ensure `.claude/sessions/` exists (create if not). The path is the same under every harness: it is the repo's convention, not Claude Code's.
2. Filename: `YYYY-MM-DD-verb-noun.md` (verbs: `add-`, `fix-`, `refactor-`, `investigate-`)
3. Use template at `references/session-template.md`
4. Keep it **lean** — since auto-memory captures durable facts, the log only needs: summary, file list, commit SHAs, and any decisions that are specific to this session (not generalizable)
5. Update `.claude/sessions/index.md` (create if missing) with a one-line entry

### 4. Curate memory — promote AND demote (batched)

Anything the user taught you this session that will matter in **future** sessions belongs in a durable home — but **memory is the last resort, not the first.** Memory loads into context *every session*, so an over-full index makes the agent dumber, not smarter. Keep the hot index lean.

**4a. Pick the right home (decision order — stop at the first that fits):**

1. **Can a hook enforce it?** → write/extend a hook (a pre-commit check, an output validator). Strongest: the agent literally *can't* forget.
2. **Is it task know-how?** → write/extend a **skill** (loads only for that task, can be as rich as needed).
3. **Is it a project/code fact?** → it's re-readable from the repo; don't store it at all.
4. **Is it personal context or a cross-session preference with no code home?** → *then* a memory file.

**4b. Promote (only what survives 4a as a genuine memory).** Scan for candidates across the four types:

- **user** — role, expertise, current focus, preferences revealed
- **feedback** — corrections or validated approaches ("always do X", "don't Y")
- **project** — stakeholders, why-decisions, deadlines, non-code facts
- **reference** — external systems discovered (dashboards, issue trackers, channels)

**Filter before proposing (drop silently):** code patterns / file paths / architecture (re-readable), git history, debugging fix recipes (the fix is in the code), anything already in CLAUDE.md, ephemeral task state.

**Deduplicate:** grep the memory index(es) — `MEMORY.md`, plus `REFERENCE.md` if this setup has one — for each candidate's topic; **update** an existing file rather than create a duplicate.

**Resolve the memory store first (both harnesses write to the same one):**

1. If `CLAUDE_MEMORY_DIR` is set in the environment, or a settings file sets `autoMemoryDirectory` (Claude Code precedence: `.claude/settings.local.json`, then `.claude/settings.json` in the repo, then `~/.claude/settings.json`), that directory is the store.
2. Otherwise it is `~/.claude/projects/<slug>/memory/`. Start from the directory the session was launched in: if it is inside a git repo, use that repo's root (`git rev-parse --show-toplevel`; in a linked worktree, the main worktree's root, first line of `git worktree list`); outside a git repo, use the launch directory itself. `<slug>` is that absolute path with every character that is not a letter or digit replaced by `-` (`/Users/me/repos/app.io` → `-Users-me-repos-app-io`; dots, underscores, and spaces all become `-`). Claude Code keys memory to that root even when launched in a subdirectory or worktree; if `CLAUDE_CODE_PROJECT_DIR_NAME` is set, that value is the slug instead. Compute it from this session, never from a path fragment seen elsewhere.
3. If that directory does not exist, print `memory: no store at <path> for this project — skipping step 4` and skip promotions and demotions. Never create the store, and never write to another project's store. If it exists but is empty (Claude Code creates it on first launch), it is the standard auto-memory shape below: write the first file and create `MEMORY.md` yourself.

Claude Code reads this store natively; under Pi you read and write the same files with ordinary file tools, so a learning captured in either harness shapes the next session in both.

**Write in this machine's memory format.** Read two or three existing memory files first and match their frontmatter exactly — memory setups differ. The two shapes you'll meet:

- **Standard auto-memory** (the default): frontmatter is `name` / `description` / `metadata.type`. After writing each file, add a one-line pointer to `MEMORY.md` yourself.
- **Tiered index** (existing files carry a `tier:` field and the repo has an index-builder script, e.g. `bin/build-memory-index.py`): tag every memory `tier: law | active | reference | archive` at write — **law** (decision-changing rule) and **active** (live project) load every session; **reference** is grepped on demand; **archive** leaves the indexes. Then **regenerate the indexes with the script — never hand-edit them**; they're derived artifacts and hand edits are reverted on the next regen.

**4c. Demote / retire (the half wrap-up used to skip).** Scan the *existing* index for entries that should leave it:

- a `project` whose work finished, shipped, or was abandoned
- a lesson that now has a **hook or skill** home (e.g. it was folded into a skill this session) — leave a pointer to the new home
- a tool assessment whose verdict is in

Retire per the local format: set `tier: archive` on a tiered setup; on standard auto-memory, delete the file (or fold anything still useful into a related memory) and remove its `MEMORY.md` line.

**Present promotions + demotions as one numbered list** (type, one-liner; include the proposed tier on tiered setups):

```
Memory changes:
  1. [feedback]         user prefers argparse over click for small CLIs
  2. [project]          sync CLI rewrite — phase 2 in progress
  3. RETIRE project_foo   (shipped this session)
  4. RETIRE reference_x   (now covered by the foo-debug skill)
```

Ask **once**: "Apply which? `[numbers]`, `all`, or `none`." Don't ask per-item; rejected candidates don't return this session.

If nothing survived filtering and no demotions apply, skip this step silently.

### 5. Ship any remaining changes

If the doc review or session log produced uncommitted changes, invoke the ship skill to commit and push them: load `ship/SKILL.md` from the same skills directory as this file and follow it (`/ship` in Claude Code, `/skill:ship` in Pi). Do not commit manually — ship has the verification and safety logic.

### 6. Summary

Compact closeout:

```
Session scope:  <N commits, M files, ±LOC>
Docs updated:   <list or "none">
Session log:    .claude/sessions/<file>  (or "skipped — small session")
Memory added:   <N entries>  (or "none")
Shipped:        <sha list from /ship, or "nothing to commit">
```

## Why Split From `/ship`

Running a full README/CLAUDE.md re-read and a session log after every commit is too heavy — users stop running the skill and docs drift. Running them once at session end is affordable and catches the drift `/ship`'s cheap diff-driven check misses. See `/ship` for the fast path.

## Common Mistakes

| Mistake | Do instead |
|---|---|
| Duplicate `/ship`'s targeted doc check | Only do the semantic/holistic read here |
| Write verbose session logs repeating commit messages | Log = summary + file list + SHAs + session-specific decisions |
| Save code patterns to memory | Memory is for preferences and non-obvious project facts |
| Commit manually at the end | Delegate to `/ship` so verification still runs |
| Run for every small session | Skill is opt-in; small sessions don't need it |
| Ask per-item for memory candidates | Present all at once; user picks with numbers |
| Silently bundle pre-session uncommitted work | Run the dirty-start check in Step 1 first |
| Guess the memory store from a path you noticed somewhere | Compute it from this repo's root per Step 4; if it doesn't exist, say so and skip |
| Treat `/ship` as a command the harness must provide | Load `ship/SKILL.md` and follow it; the slash forms are just how users spell it |

## Notes

- **Portability:** session logs live in the repo (git-tracked) and sync via git. Auto-memory is machine-local unless the setup has its own sync mechanism (e.g. a `sync-memory.sh` between writer machines) — don't assume a memory written here is visible elsewhere; check the memory directory's own conventions. Across harnesses on one machine it is shared: Pi and Claude Code resolve the same store per Step 4.
- Pairs with `/grill` (adversarial review of a change, run before `/ship`) and `/ship` (per-chunk commit + push). Wrap-up assumes shipped work was already verified and reviewed; it closes out the session, it doesn't re-audit the code.
