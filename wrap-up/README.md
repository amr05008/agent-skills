# /wrap-up

An Agent Skills-standard skill for Claude Code and the Pi coding harness that closes out a working session. Run it once at the end of a session to do the expensive semantic work that shouldn't happen on every commit: holistic doc review, a session log, and promoting durable learnings to Claude's auto-memory.

## The problem

After a working session with Claude Code, there's a class of work that's too heavy to do on every commit but matters for the long run:

- Did we leave the README accurate? The CLAUDE.md? The ROADMAP?
- What did we actually decide today, and will future-me (or future-Claude) know why?
- Are there preferences, facts, or decisions worth teaching Claude so I don't have to re-explain next session?

Doing this ad-hoc means it usually doesn't happen. Doing it after every commit means you stop running the tool.

## What /wrap-up does

Run it once at end of session:

1. Scopes the session's cumulative work (with a dirty-start check so uncommitted WIP from *before* this session doesn't get silently bundled in)
2. Reads README / CLAUDE.md / ROADMAP holistically and proposes updates
3. Writes a lean session log to `.claude/sessions/` — git-tracked, portable across your machines
4. Extracts durable learnings from the conversation and offers them as a batched pick-list to promote to Claude's auto-memory
5. Commits any resulting changes

## A worked example

```
you:    ok, wrapping up
claude: [/wrap-up]
  Scope: 2 commits, 3 files, +87/-12
  Dirty-start check: all uncommitted changes are from this session ✓
  Docs: README current. CLAUDE.md references a renamed function — proposed edit:
    - Run `buildSync()` to trigger a rebuild.
    + Run `build()` to trigger a rebuild.
  Apply? [Y/n]: y
  Session log: .claude/sessions/2026-04-20-add-sync-flags.md — create? [Y/n]: y
  Memory candidates:
    1. [project] sync command's --dry-run output goes to stderr (non-obvious)
    2. [feedback] user prefers argparse over click for small CLIs (validated)
  Save which? [numbers / all / none]: 1
  Saved 1 memory.
  Committing doc update + session log...
```

## Why session logs AND auto-memory?

They serve different purposes. `/wrap-up` actively splits new learnings between them so neither ends up bloated:

- **Session log** — per-session narrative. Git-tracked, human-readable, syncs across your machines via git, visible to teammates, portable between personal and work laptops.
- **Auto-memory** — durable preferences and project facts that should shape **future** sessions. Machine-local (doesn't sync between laptops). It's Claude Code's store, but `/wrap-up` writes to it from Pi too, so a learning captured under Pi shapes the next Claude Code session on that machine. If a project has no memory store yet, wrap-up says so and skips rather than creating one.

Rule of thumb: if it needs to survive the move between machines or be visible to a teammate, it's a log entry. If it's "something Claude should remember so I don't re-explain it," it's a memory.

## What /wrap-up will NOT do

- Edit code (beyond doc updates it explicitly proposes)
- Make architectural or product decisions
- Close issues or update Linear / Jira / Notion trackers
- Save anything to memory without your confirmation
- Run meaningfully if invoked repeatedly — this skill is once-per-session
- Re-run tests or verify the codebase — that's the job of your per-commit flow

## Install

One checkout serves both harnesses. Claude Code discovers skills in `~/.claude/skills/<name>`; Pi discovers them in `~/.agents/skills/<name>`. The bundled script links this directory into both:

```bash
scripts/install-skill-links.sh --dry-run   # preview
scripts/install-skill-links.sh --yes       # apply (add --force to repoint a link to another checkout)
```

Then start a new session (skills load at session start) and run `/wrap-up` in Claude Code or `/skill:wrap-up` in Pi at the end of a working session. Both load the same `SKILL.md`.

### Dependencies

- **`git`** (required)
- A project in a git repo (session logs go to `.claude/sessions/` in the repo root)

### Using on multiple machines

Skill directories don't auto-sync between machines. Keep this skill in a git repo you pull on each machine and run `scripts/install-skill-links.sh --yes` there; it only creates symlinks, so it's safe to re-run.

Session logs live in each project repo and sync via git. Auto-memory is machine-local — if something needs to survive the move between laptops, put it in a session log, not memory.

## Customization

Natural-language overrides — no flags needed:

| You say | Claude does |
|---|---|
| "wrap up but skip the session log" | Skips Step 3 |
| "don't save any memories" | Skips Step 4 |
| "wrap up fast" | Skips the holistic doc read — does session log + memory only |
| "just the doc review" | Only runs Step 2 |

## Design notes (for anyone modifying)

- **`/wrap-up` is intentionally expensive.** It does the once-per-session work that shouldn't run on every commit. If something needs to run per-commit, it doesn't belong here.
- **Memory promotion is batched.** Per-item prompts ("save this? save this? save this?") create friction that makes users skip the whole step. Show the numbered list once, let the user pick with `[numbers / all / none]`.
- **Dirty-start check before bundling.** If uncommitted work predates the session, ask before sweeping it into the session log or commit. Silently bundling unfamiliar WIP is a trust-breaker.

Source of truth: `SKILL.md` in this directory. The YAML frontmatter (`description`) controls when either harness invokes the skill — change carefully. The skill needs only `git` and a shell; it never depends on an MCP, so it behaves the same in Claude Code and Pi.

## Pairs well with /ship and /grill (optional)

`/wrap-up`'s final step — committing any doc updates or session log produced — will delegate to `/ship` (`/skill:ship` in Pi) if you have that companion skill installed (it's designed for the per-commit loop: verification, commit message drafting, push, PR creation). If you don't have `/ship`, `/wrap-up` still works; it just prompts you to commit manually. `/grill` completes the trio as the adversarial pre-commit review, run before `/ship`. None of the three requires the others.

## Feedback

This is v1. Expect to tune it. Edits to `SKILL.md` take effect next session.
