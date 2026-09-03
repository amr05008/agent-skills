# /ship

An Agent Skills-standard skill for Claude Code and the Pi coding harness that ends the "I finished a thing, now what?" plumbing loop. Run it any time you've finished a logical chunk of work — it verifies, commits, pushes, and offers to open a PR, using drafts you approve rather than prompts you answer.

## The problem

You're pairing with Claude Code. You finish a chunk. Now you need to:

- Run the tests / lint / typecheck
- Figure out which files to stage (without accidentally committing `.env`)
- Write a commit message matching the repo's style
- Push to the right branch
- Open a PR with a useful description

By the time you've done this seven times in a session, you've burned 15 minutes on plumbing and lost the thread of what you were actually building.

## What /ship does

Run it any time you've finished a logical unit of work:

1. Checks if there's anything to ship (exits cleanly if not)
2. Spots docs the diff just made stale — targeted grep, not a full re-read
3. Runs your project's tests, lint, and typecheck **in parallel**, auto-detected from `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `Makefile`
4. Stages files safely — no `git add -A`; warns on anything secret-looking
5. Drafts a commit message matching your repo's style
6. Commits and pushes — pausing first if you're about to commit straight to `main`, unless the repo's `CLAUDE.md` allows it or you've already OK'd it this session
7. If you're on a feature branch with no open PR, offers to open one via `gh pr create`, using your repo's PR template

You approve the commit message and PR body before they go out. Nothing ships silently.

## A worked example

```
you:    let's add a --dry-run flag to the sync command
claude: <writes the code>

you:    ship it
claude: [/ship]
  Verify: npm test ✓  npm run lint ✓  npm run typecheck ✓
  README "Usage" section references the sync command — proposed edit:
    - `sync` writes to the target immediately
    + `sync` writes to the target immediately (or use `--dry-run` to preview)
  Apply? [Y/n]: y
  Commit: "Add --dry-run flag to sync command"
  Push? [Y/n]: y
  Branch `feat/dry-run` has no open PR — open one? [Y/n]: y
  PR: https://github.com/you/repo/pull/42 (draft)
```

Keystrokes of user input: about a dozen across verify + commit + push + PR. Everything else was drafted from the diff.

## What /ship will NOT do

- Deploy, release, or touch production — this is ship-to-remote, not ship-to-prod
- Force-push or rewrite history — never without explicit request, never to `main`
- Merge PRs — `/ship` opens them; merging is still your call
- Work outside git repos
- Auto-update an existing PR body (mentions the PR, doesn't touch it)
- Run when there's nothing to ship (cleanly exits — safe to invoke speculatively)

## Install

One checkout serves both harnesses. Claude Code discovers skills in `~/.claude/skills/<name>`; Pi discovers them in `~/.agents/skills/<name>`. The bundled script links this directory into both:

```bash
scripts/install-skill-links.sh --dry-run   # preview
scripts/install-skill-links.sh --yes       # apply (add --force to repoint a link to another checkout)
```

Then start a new session (skills load at session start) and run `/ship` in Claude Code or `/skill:ship` in Pi. Both load the same `SKILL.md`.

### Dependencies

- **`git`** (required)
- **`gh`** (GitHub CLI) — optional but recommended; needed for the PR-creation step. Install from [cli.github.com](https://cli.github.com); authenticate with `gh auth login`.
- Your project's existing verification commands (`npm test`, `pytest`, `cargo test`, etc.) — `/ship` auto-detects them, it doesn't install them.

### Using on multiple machines

Skill directories don't auto-sync between machines. Keep this skill in a git repo you pull on each machine and run `scripts/install-skill-links.sh --yes` there; it only creates symlinks, so it's safe to re-run. No hardcoded paths — portable across macOS / Linux.

## Customization

Natural-language overrides — no flags needed:

| You say | Claude does |
|---|---|
| "ship but don't push" | Commits locally, skips the push |
| "ship fast" / "skip verify" | Commits without running tests / lint / typecheck |
| "show me what /ship would do" | Dry run — lists everything without committing |
| "just push, no PR" | Skips the PR creation step |
| "ship with a ready PR" | Drops `--draft` on the PR |

## Design notes (for anyone modifying)

- **`/ship` is intentionally cheap.** It's designed to run many times per session, so the doc check is diff-driven (targeted grep) rather than a full README re-read. Anything expensive that only needs to run once per session belongs elsewhere.
- **Drafts, not prompts.** Claude drafts the commit message, PR body, and doc edits from the diff. The user approves or edits. Asking "what should the commit message be?" is exactly the plumbing tax this skill exists to remove.

Source of truth: `SKILL.md` in this directory. The YAML frontmatter (`description`) controls when either harness invokes the skill — change carefully. The skill needs only `git` and optionally `gh`; it never depends on an MCP, so it behaves the same in Claude Code and Pi.

## Pairs well with /grill and /wrap-up (optional)

- **`/grill`** — adversarial review of the change itself, run *before* `/ship`. `/ship` verifies the checks pass; `/grill` cross-examines whether the change is right.
- **`/wrap-up`** — end-of-session rituals: holistic README / CLAUDE.md review, session logs in `.claude/sessions/`, and promoting durable learnings to Claude's auto-memory. Runs once at session end.

Use them together or just use `/ship` standalone; none requires the others.

## Feedback

This is v1. Expect to tune it. Edits to `SKILL.md` take effect next session.
