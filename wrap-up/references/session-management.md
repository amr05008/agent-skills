# Session Management

Guidelines for tracking agent working sessions across projects, whichever harness (Claude Code or Pi) ran them.

## Opting In (the tracking gate)

**Session tracking is opt-in per repo, and git tracking is the signal.** Before writing a log, check whether the repo already keeps them:

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

- **`OPTED-IN`** → the repo keeps session logs. Check the target paths (below), then write.
- **`SKIP`** → this repo doesn't keep them. Skip the log; don't create the directory.
- **`STOP`** → tracked, but the directory isn't in this checkout (sparse checkout, or an unstaged deletion). Skip and say which; don't create it.
- **`GIT-ERROR`** → the check failed. This is *not* an opt-out — report the failure rather than silently skipping.

**Then check the actual target paths**, once the filename is chosen — opt-in is not the same question as "can this file be committed":

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

Run it on the real log filename and on `index.md` whenever you'll create or update it. Never on a placeholder: a pattern can single out a date prefix, an extension, or `index.md` itself, so a stand-in name proves nothing. Paths must be repo-relative including the `.claude/sessions/` prefix — a bare filename resolves to the repo root and answers about the wrong file.

Passing is positive: every target must return its own `OK:` line. No output is an incomplete or failed check — never permission to write. The status match is exact (0 ignored, 1 not ignored, 128 failed), captured via `if`/`else` so an ordinary 1 can't kill a caller running under `set -e`.

Four details are load-bearing:

- `:/` anchors the pathspec to the repo root, so the answer is right from any subdirectory. A bare `.claude/sessions/` reads as "untracked" from anywhere but the root, silently disabling logging in a repo that does keep them.
- Each command's exit status is checked, not just its output. `git ls-files ... | head -1` yields `head`'s status, so a git failure looks exactly like an opt-out and fails toward dropping a wanted log.
- Tracking and ignoring are independent: adding a `.gitignore` pattern doesn't un-track files already in the index, so opt-in never proves a *new* file is committable.
- Both blocks are wrapped in `( … )` so their variables stay out of the caller's shell.

**To opt a repo in:** write one log and `git add` it. There's no config to set — the next run sees the tracked file and turns itself on.

**Why gate on tracking rather than always writing:** many repos gitignore `.claude/` wholesale. There, a session log is untracked, unsynced, unbacked-up, and never loaded into context — write-cost with no read-benefit, accumulating unread. Where logs *are* tracked they're load-bearing: they sync across machines, they're visible to teammates, and a project may cite a specific log as the canonical recipe for a recurring task. The tracking test separates those two cases; the target-path check then catches the overlap, where a repo tracks old logs but ignores new ones.

The durable material has better homes than an untracked log anyway: cross-session facts and preferences belong in memory, decisions about a thing belong next to the thing (that project's `README.md` or `docs/`), and why-this-change belongs in the commit body.

## Directory Structure

Each project using session tracking should have:
- `.claude/sessions/` - Detailed logs of working sessions
- `.claude/sessions/index.md` - Quick lookup by date/topic
- `.claude/decisions/` - Rationale for major architectural choices

The **directory** is only ever created by a human opting the repo in — never by the agent writing a log. Inside an already-opted-in directory the agent may create `index.md` if it's missing, since a human who opts in by git-adding a single log won't have one yet.

## Before Starting Work

- Check `.claude/decisions/` for existing rationale
- Check `.claude/sessions/` for relevant prior work
- Don't re-litigate solved problems without good reason

## When to Create a Session File

Assumes the tracking gate above passed. If it didn't, none of the below applies — skip the log.

**Do create for:**
- New features or pages
- Non-trivial bug fixes
- Architectural changes
- Multi-file refactors
- Complex investigations (even if unresolved)

**Skip for:**
- Typo fixes, single-line changes
- Pure Q&A with no code changes
- Any repo that doesn't git-track `.claude/sessions/` (see the gate above)

## Session File Format

**Filename:** `YYYY-MM-DD-verb-noun.md`
- Lowercase with hyphens
- Start with action: `add-`, `fix-`, `refactor-`, `investigate-`
- Examples: `2026-01-02-add-dark-mode.md`, `2026-01-02-fix-auth-bug.md`

**Template:**

```markdown
---
date: YYYY-MM-DD
summary: One-line description
tags: [relevant, tags]
---

## Summary
What was accomplished (2-3 sentences)

## Changes
- List of files changed and why

## Decisions
Key choices and rationale (if any)

## Notes
Useful context for future reference (optional)
```

## Multi-Day Work

For work spanning multiple days:
- Use the start date in filename
- Update the same session file as work continues
- Add dated subsections if helpful

## After Creating a Session

1. Update `.claude/sessions/index.md` with one-line entry
2. If a major architectural decision was made, add to `.claude/decisions/`

## References

- **Session history**: `.claude/sessions/`
- **Architecture decisions**: `.claude/decisions/`
- **Project ideas**: `PROJECT_IDEAS.md` (gitignored, per-project)
