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
| **Session log + index update** | — | ✓ *(only if the repo git-tracks `.claude/sessions/`)* |
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

**Check A — is this repo opted in?** This runs before every other check in this step:

```sh
( if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "GIT-ERROR: not inside a git work tree"
  elif ! logs=$(git ls-files ':/.claude/sessions/' 2>/dev/null); then
    echo "GIT-ERROR: tracking query failed"
  elif [ -z "$logs" ]; then
    echo "SKIP: repo does not track .claude/sessions/"
  elif [ ! -d "$root/.claude/sessions" ]; then
    echo "STOP: tracked, but .claude/sessions/ is absent from this checkout"
  else
    echo "OPTED-IN"
  fi )
```

| Result | What it means | Do |
|---|---|---|
| `OPTED-IN` | The repo keeps session logs and the directory is here | Continue — Check B below still has to pass before you write |
| `SKIP` | The repo opted out (or never opted in) | Skip the log entirely — write nothing, create nothing. Report `skipped — repo doesn't track .claude/sessions/` in the Step 6 summary |
| `STOP` | Logs are tracked but the directory isn't in this checkout (sparse checkout, or an unstaged deletion) | Skip the log and say which of the two it was. **Don't create the directory** — tracking is the opt-in authority, but the directory existing is a separate prerequisite for writing |
| `GIT-ERROR` | The check itself failed | **Not an opt-out.** Say the check failed and why; don't silently skip as though the repo opted out |

A repo opts in by git-adding a single session log; the test then turns itself on with no config to set.

Check A proves the repo *wants* logs. It does **not** prove the specific file you're about to write can be committed — that's Check B, after you've chosen the filename.

Four details are load-bearing, so don't "simplify" them away:

- **`:/` anchors the pathspec to the repo root.** A bare `.claude/sessions/` is resolved relative to the current directory, so it reports "untracked" from any subdirectory — silently disabling logging in repos that do keep them.
- **Each git command's exit status is checked, not just its output.** `git ls-files ... | head -1` returns the status of `head`, so a git failure (exit 128 on a corrupt index, or outside a repo) yields empty output and success — indistinguishable from a genuine opt-out, and it fails toward dropping a log someone wanted.
- **Tracking and ignoring are independent.** Git does not un-track files when a `.gitignore` pattern is added later, so a repo can have tracked logs *and* ignore new ones. Check A passing is not evidence that a new file is committable.
- **The block is wrapped in `( … )`.** It assigns `root` and `logs`; a subshell keeps those out of the caller's shell.

**Why this is gated.** Where `.claude/` is gitignored, a session log is untracked, unsynced, unbacked-up, and never loaded into context — pure write-cost for no read-benefit. And the durable material has better homes than a fourth copy of it:

- cross-session facts and preferences → **memory** (Step 4 — and it's the expensive home, since memory loads *every* session, which is why Step 4 treats it as the last resort)
- decisions about a thing → **next to the thing**, in that project's `README.md` or `docs/`
- why-this-change → the **commit body**

A session log nobody opens is a fourth copy that can only go stale. Where the repo does track them, they're load-bearing — some projects cite a specific log as the canonical recipe for a recurring task — so the tracking test keeps the habit alive exactly where it's earning its keep.

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
1. Use the repo's existing `.claude/sessions/` as the destination — Check A confirmed it's tracked and present — but **don't write yet**; Check B below still has to pass. **Never create the directory**: an untracked `.claude/sessions/` is how a silent pile of unread logs starts. The path is the same under every harness: it is the repo's convention, not Claude Code's.
2. Filename: `YYYY-MM-DD-verb-noun.md` (verbs: `add-`, `fix-`, `refactor-`, `investigate-`)
3. **Check B — can these exact paths be committed?** Run it on the filename you just chose, plus `index.md` whenever you'll create *or* update it (step 6). Check the real paths, never a stand-in: ignore patterns can single out a date prefix, an extension, or `index.md` itself, so a placeholder name proves nothing about the file you're actually writing.

   ```sh
   ( root=$(git rev-parse --show-toplevel 2>/dev/null) \
       || { echo "GIT-ERROR: not a work tree"; exit 0; }
     # Repo-relative paths, .claude/sessions/ prefix included. Replace these
     # with the real filename you chose; add index.md whenever you'll touch it.
     set -- ".claude/sessions/2026-09-11-add-thing.md" ".claude/sessions/index.md"
     [ "$#" -gt 0 ] || { echo "GIT-ERROR: no target paths given"; exit 0; }
     for f in "$@"; do
       if git check-ignore -q "$root/$f" 2>/dev/null; then rc=0; else rc=$?; fi
       case $rc in
         0) echo "STOP: $f is gitignored — it could not be committed" ;;
         1) echo "OK: $f" ;;
         *) echo "GIT-ERROR: ignore check failed for $f (status $rc)" ;;
       esac
     done )
   ```

   Substitute your real paths into the `set --` line. They must be **repo-relative and include the `.claude/sessions/` prefix** — a bare filename resolves to the repo root and silently answers about the wrong file.

   **Passing is positive, and silence is not a pass.** Every path you're about to write must come back on its own `OK:` line naming that exact file. No output at all is an incomplete or failed check — never permission to write. Any `STOP` → don't write that file; report `skipped — <path> is gitignored; it couldn't be committed` and leave it to the user; **never `git add -f`** around the ignore. Any `GIT-ERROR` → say the check failed; don't write on an unanswered question.

   The status match is exact — `check-ignore` exits 0 ignored, 1 not ignored, 128 failed — and it's captured via `if`/`else` rather than a bare command so that a caller running under `set -e` isn't killed by the ordinary "not ignored" 1 before `case` ever runs.

4. Use template at `references/session-template.md`
5. Keep it **lean** — since auto-memory captures durable facts, the log only needs: summary, file list, commit SHAs, and any decisions that are specific to this session (not generalizable)
6. Update `.claude/sessions/index.md` (create if missing — it's inside an already-opted-in directory) with a one-line entry. It must have come back `OK` from Check B, whether you're creating it or updating an existing one

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
- anything out of date, or that nobody will look up again

**Retire, don't park.** On a tiered setup, demote to `reference` only what will actually be looked up again. Anything out of date or unlikely to be reused goes straight to `archive`: a cold tier full of stale facts still misleads whoever greps it.

Retire per the local format: set `tier: archive` on a tiered setup; on standard auto-memory, remove its `MEMORY.md` line and either delete the file, fold anything still useful into a related memory, or move it to an `archive/` subfolder the index doesn't list — prefer the move when the store isn't under version control, since a deleted memory there is gone for good.

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
Session log:    .claude/sessions/<file>
                (or "skipped — small session"
                 / "skipped — repo doesn't track .claude/sessions/"
                 / "skipped — <path> is gitignored; it couldn't be committed"
                 / "skipped — .claude/sessions/ absent from this checkout"
                 / "skipped — tracking check failed: <reason>")
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
| Write a session log into a gitignored `.claude/` | Run Step 3's gate first and honor `SKIP`/`STOP`; say so in the summary |
| Read a failed git command as "the repo opted out" | `GIT-ERROR` is not `SKIP` — report the failure instead of silently dropping the log |
| Treat tracked old logs as proof a new log is trackable | A later `.gitignore` doesn't un-track old files — Check B tests the real path |
| Ignore-check a placeholder name instead of the real one | Patterns can target a date prefix or `index.md`; Check B must run on the paths you'll actually write |
| Read Check B's silence as a pass | No output is an incomplete or failed check, never permission to write — require an explicit `OK:` line per target |
| Pass Check B a bare filename | Paths must be repo-relative including `.claude/sessions/`, or it answers about the wrong file |
| Read `check-ignore`'s nonzero exit as "not ignored" | 1 is not-ignored, 128 is failure — match the exact status or you write on an error |
| Create `.claude/sessions/` so there's somewhere to put the log | Never create it — that's what starts an untracked, unread pile. The repo opts in by git-adding a log |
| Guess the memory store from a path you noticed somewhere | Compute it from this repo's root per Step 4; if it doesn't exist, say so and skip |
| Treat `/ship` as a command the harness must provide | Load `ship/SKILL.md` and follow it; the slash forms are just how users spell it |

## Notes

- **Portability:** session logs sync via git *only in repos that actually track `.claude/sessions/`* — plenty of repos gitignore `.claude/` wholesale, and there a log would be local-only, unsynced and unbacked-up. That's what Step 3's tracking test checks before writing one; don't assume a log written on one machine is visible on another until you've confirmed the repo tracks them. Auto-memory is machine-local unless the setup has its own sync mechanism (e.g. a `sync-memory.sh` between writer machines) — don't assume a memory written here is visible elsewhere; check the memory directory's own conventions. Across harnesses on one machine it is shared: Pi and Claude Code resolve the same store per Step 4.
- Pairs with `/grill` (adversarial review of a change, run before `/ship`) and `/ship` (per-chunk commit + push). Wrap-up assumes shipped work was already verified and reviewed; it closes out the session, it doesn't re-audit the code.
