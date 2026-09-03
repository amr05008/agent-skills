# Session Management

Guidelines for tracking agent working sessions across projects, whichever harness (Claude Code or Pi) ran them.

## Directory Structure

Each project using session tracking should have:
- `.claude/sessions/` - Detailed logs of working sessions
- `.claude/sessions/index.md` - Quick lookup by date/topic
- `.claude/decisions/` - Rationale for major architectural choices

## Before Starting Work

- Check `.claude/decisions/` for existing rationale
- Check `.claude/sessions/` for relevant prior work
- Don't re-litigate solved problems without good reason

## When to Create a Session File

**Do create for:**
- New features or pages
- Non-trivial bug fixes
- Architectural changes
- Multi-file refactors
- Complex investigations (even if unresolved)

**Skip for:**
- Typo fixes, single-line changes
- Pure Q&A with no code changes

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
