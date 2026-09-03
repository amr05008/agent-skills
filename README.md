# agent-skills

[Agent Skills](https://agentskills.io)-standard skills for [Claude Code](https://claude.com/claude-code) and the `pi` coding agent (the Pi harness). They cover the loop around a chunk of work: cross-examine the change, commit and push it, close out the session.

| Skill | Use it when | Claude Code | Pi |
|---|---|---|---|
| [`grill`](grill/) | After writing or changing code, before it ships. Switches the agent from author to opposing counsel: six adversarial passes, a verdict of SHIP or DON'T SHIP. | `/grill` | `/skill:grill` |
| [`ship`](ship/) | A logical chunk is done. Verifies (tests, lint, typecheck, in parallel), stages safely, drafts the commit message from the diff, pushes, offers a PR on feature branches. | `/ship` | `/skill:ship` |
| [`wrap-up`](wrap-up/) | Once, at the end of a session. Holistic doc review, a lean session log in `.claude/sessions/`, and a batched pick-list of learnings to promote to auto-memory. | `/wrap-up` | `/skill:wrap-up` |

Each directory holds `SKILL.md` (what either harness loads), a `README.md` with a worked example and design notes, and `scripts/install-skill-links.sh`. The skills need only `git` and a POSIX shell; `ship` uses `gh` when it is there. No MCP servers, no harness-specific tools, so they behave the same in both harnesses. Each works standalone; together they form `/grill` → `/ship` → `/wrap-up`.

## Install

One checkout serves both harnesses. Claude Code discovers skills in `~/.claude/skills/<name>`, Pi in `~/.agents/skills/<name>`; the bundled script symlinks a skill into both.

```bash
git clone https://github.com/amr05008/agent-skills.git ~/repos/agent-skills
for s in grill ship wrap-up; do
  sh ~/repos/agent-skills/$s/scripts/install-skill-links.sh --yes
done
```

Then start a new session (skills load at session start). Use `--dry-run` first to preview what the script would link.

The script creates symlinks and never overwrites a regular file or directory. If a hand-copied version of a skill already sits at `~/.claude/skills/<name>` or `~/.agents/skills/<name>`, remove it first; if a symlink there points at another checkout, add `--force` to repoint it.

## Update

```bash
git -C ~/repos/agent-skills pull
```

Nothing to re-link: the symlinks follow the checkout. A new session picks up the change.

## About this repository

This is a publish target. Its contents are generated from the author's working copy by a publish script and overwritten on every publish, so edits made here are lost. Please open an issue for bugs and suggestions.
