---
name: ship
description: Use when the user wants to commit and push a chunk of work mid-session — triggered by /ship in Claude Code, /skill:ship in Pi, "ship it", "commit and push", or finishing a logical unit. Safe to run many times per session. For end-of-session wrap-up, use /wrap-up instead. Works from Claude Code or Pi.
compatibility: Requires git and a POSIX shell inside a git repository. gh (GitHub CLI) is optional, used only for repo visibility and PR creation. No MCP or harness-specific tool.
---

# Ship

Commit and push the current chunk of work with automated verification, a targeted doc-staleness check, and (on feature branches) PR creation. Lightweight enough to run many times per session.

## When to Use

- User invokes `/ship` or says "ship it" / "commit and push" / "push this"
- A logical chunk of work is done and ready to go to remote
- **Not** for end-of-session cleanup — `/wrap-up` owns session logs and holistic doc review

## Harness Portability

- One Agent Skills-standard workflow for both harnesses: `/ship` in Claude Code, `/skill:ship` in Pi, or invoked naturally. Everything below uses `git`, `gh`, and the shell; no MCP or harness tool is required.
- "Run in parallel" means: issue the commands concurrently if the harness runs sibling tool calls in parallel, otherwise one after another. Order never matters for those reads or checks.
- Cross-skill references name the skill, not a slash command: `/wrap-up` and `/grill` are the user-facing spellings (`/skill:wrap-up`, `/skill:grill` in Pi) of skills that live beside this one.
- Machine setup is `scripts/install-skill-links.sh` beside this file: `--dry-run` to preview, `--yes` to link this checkout into `~/.agents/skills/ship` (Pi) and `~/.claude/skills/ship` (Claude Code).

## What `/ship` Will Not Do

- Merge, rebase, squash, or rewrite history
- Create releases, tags, or changelogs
- Deploy or trigger CI/CD manually
- Force-push (never to `main`/`master`; elsewhere only on explicit user request)
- Resolve merge conflicts (surfaces them and stops)
- Auto-update an existing PR body (mentions the existing PR but does not touch it)
- Run when there's nothing to ship (cleanly exits — safe to invoke speculatively)

## Workflow

Run each step in order. Short-circuit and exit if there's nothing to do.

### 1. Is there work to ship?

Run in parallel:
- `git status --short`
- `git diff --stat HEAD`
- `git log -n 5 --oneline` (to learn the repo's commit style)

If working tree is clean, report "nothing to ship" and exit.

### 2. Targeted doc staleness check (diff-driven)

**Do not re-read full docs.** Only act on signals from the diff:

| Diff signal | Action |
|---|---|
| Symbol renamed/removed (function, class, export, CLI flag) | Grep the old name across `*.md` files. If hits → propose edits. |
| File moved or deleted | Grep the old path across `*.md`, especially `CLAUDE.md`. |
| `package.json` scripts changed | Check README "Usage" / "Scripts" section. |
| Env var added/renamed (`.env.example` or `process.env.X`) | Check README + `CLAUDE.md` for references. |
| CLI entry point or `bin` script changed | Check README install/run section. |

**`CLAUDE.md` is stricter**: it instructs Claude directly, so stale paths or commands silently mislead future sessions. Flag `CLAUDE.md` issues even for small diffs.

If no signals hit, skip silently. Do not narrate "I checked and found nothing."

### 3. Pre-flight verification (parallel)

Auto-detect the project's verification commands, then run applicable ones **concurrently** (sibling tool calls in one turn; see Harness Portability).

Detection order (stop at first match that yields commands):

- **Node** (`package.json` exists): run any of `test`, `lint`, `typecheck`, `type-check` that exist in `scripts`
- **Python** (`pyproject.toml` / `setup.py`): `pytest` if installed, `ruff check .` if installed, `mypy .` if installed
- **Rust** (`Cargo.toml`): `cargo test`, `cargo clippy -- -D warnings`
- **Go** (`go.mod`): `go test ./...`, `go vet ./...`
- **Makefile**: `make test`, `make lint` (only if those targets exist)

**Skip verification when:**
- Diff touches only `*.md`, `docs/**`, `.claude/**`, `.agents/**`, `.pi/**`, or similar doc-only and harness-config paths
- User passes "skip verify" / "fast ship" / "--no-verify" (explicit opt-out only)
- No verification commands detected (note this in the final summary, don't fail)

**If verification fails:** Report the failure, do **not** commit. Ask the user whether to fix, skip, or proceed. Never pass `--no-verify` to git hooks without explicit permission.

### 4. Stage files safely

- Stage specific files: `git add <file1> <file2>`, not `git add -A` / `git add .`
- Scan for likely secrets in the candidate set: `.env`, `.env.*` (except `.env.example`), `*credentials*`, `*.pem`, `*.key`, `id_rsa*`. If present, warn and exclude by default.
- List untracked files and ask before including them.

**Public repos — scan file contents, not just filenames.** Check visibility once with `gh repo view --json isPrivate`. If the repo is public, grep the **full contents** of every touched file — not the diff — for material that shouldn't be published:

- Internal metrics, launch numbers, roadmap milestones, revenue figures
- Verbatim quotes from private or internal sources (strategy docs, product updates, work email, Slack)
- Employer or customer specifics: internal project codenames, channel names, account names
- Personal data: home address, DOB, financial detail, family-identifying specifics

The diff is not the risk surface — the file is. Sensitive material is usually **pre-existing**: added in an earlier commit and never re-read. Editing a file is the natural moment to audit the whole thing. When something turns up, prefer paraphrase over deletion — the point being illustrated almost always survives, and the specifics are what create the risk. Report findings and let the user decide before committing.

### 5. Draft the commit message

Read the full diff + `git log -n 10 --oneline` to match the repo's style.

- Subject ≤72 chars, imperative verb (`Add`, `Fix`, `Update`, `Refactor`, `Remove`)
- Body (when diff is non-trivial): explain the **why**, not the what
- Match repo conventions (conventional commits prefix, ticket refs, etc.) if present

Show the drafted message before committing. Don't ask the user to write it — draft, then let them edit or approve.

### 6. Commit and push

- **Default-branch guard:** if HEAD is on the default branch (`main` / `master` / `develop` / `trunk`), pause before committing and offer to move the work to a feature branch first (`git switch -c <name>` carries uncommitted changes with it). Proceed directly on the default branch only if the repo's `CLAUDE.md` explicitly allows it, or the user already OK'd it this session.
- Commit via HEREDOC to preserve multi-line formatting
- Push to the current branch's tracking remote
- If no tracking branch exists, ask before `git push -u origin <branch>`
- If push fails (rejected, diverged, auth), report the error. Never force-push without explicit user request, and never force-push to `main`/`master`.

### 7. Offer to open a PR (feature branches only)

After a successful push, check if a PR should be offered.

Run `gh pr list --head <current-branch> --json url,state,number` (if `gh` is available and authenticated).

**Offer a PR when all of these are true:**
- Current branch is NOT the default branch (not `main` / `master` / `develop` / `trunk`)
- No open PR exists for this branch
- `gh` CLI is installed and authenticated (`gh auth status` succeeds)

**Draft the PR:**
- Title: latest commit's subject (if single commit) or a session-theme title (if multiple commits)
- Body: bulleted list of commits since the branch diverged from the default branch, then a "Test plan" checklist if the repo uses that pattern
- If `.github/pull_request_template.md` exists, use it as the body skeleton and fill sections
- If `.github/PULL_REQUEST_TEMPLATE/` has multiple templates, list them and ask which
- Use `gh pr create --draft` by default (safer); user can say "ready PR" to drop `--draft`

Show the draft. Let the user edit or approve. Then run `gh pr create`.

**Skip silently when:**
- On the default branch
- `gh` CLI not available or unauthenticated
- An open PR for the branch already exists (mention its URL in the summary — do not auto-update it)
- User opts out ("don't open a PR", "just push")

### 8. Summary

Single compact block:

```
Shipped: <sha> <subject>
Verify:  tests ✓  lint ✓  types ✓   (or: skipped — docs-only)
Docs:    updated README.md  (or: none)
Push:    origin/<branch> ✓
PR:      https://github.com/org/repo/pull/42 (new, draft)   (or: existing #41, or: skipped)
```

## Red Flags — Stop and Ask

- About to commit to the default branch with no `CLAUDE.md` opt-in or user OK this session
- Verification command failed
- Secret-looking file in the staged set
- Branch diverged / push rejected
- Merge conflicts in the working tree
- User would need `--no-verify` to commit (hook is failing for a real reason)

## Common Mistakes

| Mistake | Do instead |
|---|---|
| `git add -A` / `git add .` | Stage specific files by name |
| Ask user for commit message | Draft from diff, show, let them edit |
| Scan every `.md` file every ship | Only check docs the diff implicates |
| Run tests serially on a harness that can run them concurrently | Dispatch tests/lint/typecheck as sibling tool calls |
| Silently skip verification | Always report what was run and what was skipped |
| Force-push on first rejection | Report the rejection and ask |
| Auto-create PR on default branch | Skip PR step entirely when on main/master |
| Auto-update an existing PR | Mention it, don't touch it |

## Notes

- Skill is intentionally diff-driven so it stays fast enough to run after every logical chunk.
- Pairs with `/grill`, which adversarially reviews the change itself before shipping — `/ship` verifies the checks pass; `/grill` cross-examines whether the change is right.
- Pairs with `/wrap-up`, which handles the semantic doc sweep and session log at the end of a session.
- PR step is skipped on the default branch — use GitHub's UI or `gh pr create` directly if you really need to PR into main.
