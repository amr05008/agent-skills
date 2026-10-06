# House config

`~/.config/competitive-analysis/house.md` is a machine-local file describing
what this particular machine can do, where its output belongs, and what
private context it holds. Phase 0 reads it before anything else.

It is **never committed anywhere.** That is the point: the skill is portable
and public, and everything that would make it specific to one person, one
company, or one machine lives here instead. Two machines running the same
skill against the same company produce different — and correctly different —
reports, because their configs differ.

**A machine with no config file is normal.** Every field below has a default,
and a run without a config is a valid generic run. The file only ever adds
capability; it never gates a run.

## Format

Plain `key: value`, one per line. Values may wrap onto indented continuation
lines. Everything after `#` is a comment.

```
byline: Jordan Ellis
output_dir: ~/research/teardowns
artifact_publish: on
sharing_note: Personal plan. Artifacts are private until shared; Share
  produces an unlisted public link — anyone holding the URL can view it,
  no account needed, and it cannot be revoked per-person.
operator_profile: none
social_reader: none
paid_sources: monid, exa
monid_reference: ~/refs/monid-cli-0.1.7.md
exa_helper: python3 ~/tools/exa
```

## Fields

| Field | Default | What it does |
|---|---|---|
| `byline` | the caller's name, or omitted | Whose name goes on the report. |
| `output_dir` | the harness's working dir | Where the `.md` lands. If it is inside a git repo, Phase 4 commits and pushes per that repo's rules. |
| `artifact_publish` | `on` | Whether Phase 4 publishes the report as an Artifact in harnesses that have the tool. Set `off` when you cannot state the environment's sharing model accurately. |
| `sharing_note` | none | **Quoted verbatim** in the closing note. See below — this field carries more weight than its size suggests. |
| `incumbent` | none | The product a teardown is measured against. |
| `incumbent_context` | none | Path to internal material about `incumbent` — a repo, a directory, a file. Read in Phase 0, labeled `INTERNAL`, and governed by the Phase 2 handling rules. |
| `slack_channels` | none | Named **public** channels a work Slack integration may read for competitive signal. Never DMs, never channels not named here. |
| `social_reader` | none | A CLI or MCP fronting X/Twitter, LinkedIn, or YouTube on this machine. Its own docs carry its verbs and rates; Phase 3 states what this skill requires of any such tool. |
| `operator_profile` | none | Where to find the caller's background, for calibrating a `me` report. Read to calibrate, never cited, never in a `team` report. |
| `paid_sources` | none | Which billable paths exist here, and against which account. |
| `monid_reference` | none | A local audited snapshot of Monid's docs to read instead of fetching the live URL. |
| `exa_helper` | none | The command that fronts Exa on this machine, with its key held outside the repo. Read only when `paid_sources` includes `exa`; drives the Phase 2 discovery pass. Its own docs carry its verbs and rates. |

## On `sharing_note`

An artifact's sharing model differs enormously between plans, and the skill
cannot detect which one it is running under. A personal plan may offer only
an unlisted public link — uncontrolled and unrevocable. A managed workspace
may default to private, offer org-scoped sharing, and block public links
entirely by policy. Those two environments call for opposite handling of the
same link, and guessing wrong is bad in both directions: describe a governed
artifact as public and the report goes unshared; describe a public one as
governed and it gets forwarded.

So write what you verified, and verify it by publishing a throwaway artifact
and reading the Share dialog — not from memory, and not by analogy to another
machine. **Note what the default is**, not only what is available: the skill
publishes without a prompt, so an unattended publish inherits the default
rather than a human's judgment. Re-verify after any workspace policy change.

If the field is missing, Phase 4 says so plainly rather than inventing a
characterization.
