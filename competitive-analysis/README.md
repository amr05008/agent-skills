# /competitive-analysis

An Agent Skills-standard skill for Claude Code and the Pi coding harness that produces an evidence-graded teardown of a company or product. Run it when you need to know what a competitor, a potential partner, or an acquisition target is actually doing — not what their homepage says they're doing.

## The problem

Ask an agent to "research this company" and you get the marketing site, paraphrased. Every claim arrives with the same confidence whether it came from an SEC filing or a founder's launch tweet, nothing is dated, and the gaps — no reviews anywhere, no hiring in a function they claim to be scaling — go unmentioned because absence doesn't look like a finding.

That output is worse than nothing. It reads authoritative, so it gets forwarded, and the unsourced number in paragraph three ends up in someone's board deck.

## What /competitive-analysis does

Treats every claim as needing a provenance label before it can be used:

1. **Reads the machine's house config** — output directory, byline, which paid sources exist here, whether artifacts get published. A capability this machine lacks becomes a stated coverage gap in the report, never a silent omission and never an improvised workaround.
2. **Resolves purpose and audience.** `me` reports can carry your private framing; `team` reports are written *to* the recipient org — no private framing, people by public role, no contact data. Audience changes what the report is, not what gets researched.
3. **Runs four required research methods**, which is where most of the alpha lives: Wayback history reconstruction (what the positioning used to say), job-listing content mining (what they're actually building, months before it ships), contradiction reconciliation (the pricing page vs. the sales deck vs. the changelog), and absence-as-evidence (the review platform with no reviews).
4. **Fans out four researchers** where the harness supports it — product/pricing history, company facts and hiring, the real competitive set (including "do nothing" and DIY), and sentiment/traction — each bounded by five hard rules, then polls the in-flight count *during* the research, not at dispatch.
5. **Grades every material claim** — direct link, evidence date, and one of VERIFIED / COMPANY-CLAIMED / ESTIMATE. Press coverage of a fundraise is COMPANY-CLAIMED, not verified.
6. **Ends with a verdict** defended by the few variables that actually decide it, plus a closing note carrying the artifact link, the coverage gaps, and total paid-source spend.

Where the house config names an Exa helper, a bounded **discovery pass** runs before the fan-out — the real competitive set, the news and funding timeline, the pricing and careers URLs — and seeds the researcher briefs. Search hits are leads, never evidence; every claim still rests on a fetched page.

For a single page rather than a whole company ("what does this new pricing page tell us"), it runs a lighter **strategic-direction mode**: no enrichment, no fan-out, no paid calls — just the page, minimal context, and an assessment.

## A worked example

```
you:    /competitive-analysis northwind.example "should we worry about them
        for our roadmap"

claude: Purpose: operator diligence. Audience: me. Output:
        2026-09-03-northwind-teardown.md

  Positioning shifted twice (VERIFIED, Wayback 2024-11 → 2026-06):
  "scheduling for agencies" → "scheduling" → "revenue operations".
  The agency language is gone from every page but the pricing FAQ.

  Hiring contradicts the pitch (VERIFIED, 6 listings, 2026-08-28): 4 of 6
  are enterprise AE and solutions-engineer roles. Zero product engineering.
  A company mid-platform-rewrite does not staff like this.

  $12M Series A (COMPANY-CLAIMED, TechCrunch 2026-05-14 — the round is the
  company's own announcement; no filing found).

  Absence: no G2 profile, no Reddit mentions in 12 months, 3 reviews on
  Capterra. For a product claiming "hundreds of teams," that silence is
  itself the finding.

  Coverage gaps: Wayback returned 503 for the pricing path (recorded, not
  routed around). No social reader on this machine — X and LinkedIn
  unsearchable from here.

  Verdict: MONITOR, don't react. They are moving upmarket and away from
  your segment; the threat is 12+ months out and would announce itself in
  their hiring first.

  Note: artifact published — <url>. Paid sources: $0.34 (Reddit, 2 calls).
```

## What /competitive-analysis will NOT do

- Invent a figure to fill a gap — a missing number is reported as missing
- Keep hammering a blocked source, or spawn helpers to route around it — a blocked source is a finding
- Spend past its ceiling (~$1.00 across all paid social per run, unless you say otherwise) or retry a failed paid call, which may already have been billed
- Let a subagent make a paid call, ever — metered paths belong to the orchestrator alone
- Put internal context into a research query, a subagent brief, or the wrong audience's report
- Push to a shared repo, sign up for a service, or hand-build authenticated calls to a platform it wasn't given access to

## Install

One checkout serves both harnesses. Claude Code discovers skills in `~/.claude/skills/<name>`; Pi discovers them in `~/.agents/skills/<name>`. The bundled script links this directory into both:

```bash
scripts/install-skill-links.sh --dry-run   # preview
scripts/install-skill-links.sh --yes       # apply (add --force to repoint a link to another checkout)
```

Then start a new session (skills load at session start) and run `/competitive-analysis <company or URL>` in Claude Code, `/skill:competitive-analysis <company or URL>` in Pi. Both load the same `SKILL.md`.

### Dependencies

- **Web research** (required) — the four required methods run on it
- **A house config** (optional, recommended) — `~/.config/competitive-analysis/house.md`, spec in `references/house-config.md`. Names this machine's output directory, byline, available paid sources, and artifact-publish setting. Never committed anywhere. Absent, every default applies and a run still works.
- **Structured enrichment** (optional) — company/contact enrichment via an MCP that provides it. Absent, the same ground is covered by web research and noted in the caveats.
- **A paid gateway** (optional) — for the coverage hole platforms like Reddit leave behind. House rules in `references/monid-house-rules.md`.
- **A social reader** (optional) — whatever CLI or MCP this machine has for X, LinkedIn, and YouTube. Absent, that becomes a stated gap.
- **`defuddle`** (optional, recommended) — a local CLI that extracts a page as markdown. First rung of the fetch ladder; it returns the page's own words, so a claim can be quoted instead of paraphrased. `npm install -g defuddle@0.19.1` (pin deliberately; bump after review, not implicitly). Absent, the ladder falls through to the harness fetch tool and the run is still correct.

Every optional dependency degrades to a coverage gap in the report. None of them is required for a run to be correct.

## Customization

Natural-language overrides — no flags needed:

| You say | Claude does |
|---|---|
| `<company> <specific-page-url>` | Strategic-direction mode: that page only, no enrichment, no paid calls |
| "for the growth team at Acme" | `team` audience — written to that org, private framing stripped |
| "audience: me" | Forces the personal report even when readers are named |
| "spend up to $5 on this" | Raises the paid-source ceiling for the run |
| "compare them to <incumbent>" | Pulls in the configured incumbent context, if this machine has one |

## Design notes (for anyone modifying)

- **The evidence label is the whole product.** A teardown that can't distinguish a filing from a launch tweet is a summary of marketing copy. VERIFIED / COMPANY-CLAIMED / ESTIMATE is cheap to write and is what makes the report safe to forward.
- **The four required methods are required because they're the ones agents skip.** They're slow, they don't feel like research, and they produce the findings no one else has. "Required" means attempted and accounted for — a method whose source is unreachable is discharged by recording the gap, not by trying harder.
- **Fan-out is bounded because it ran away once.** Four researchers became nineteen agents in six minutes with zero returns, triggered by one unreachable source that a researcher kept spawning helpers to route around. Stopping the parents did not cascade. Hence: one level deep, count agents *during* the research rather than at dispatch, stop extras by id, and treat a blocked source as a finding.
- **A spend ceiling only holds where one actor owns the whole run.** Four subagents each honoring "$1.00" is a $4.00 run, so paid calls live with the orchestrator alone — not because a subagent couldn't check a balance, but because a shared ceiling isn't a ceiling.
- **Internal context shapes which questions go out; it is never the text that goes out.** Every research path writes its query to someone else's logs, so queries are built from words a stranger could have written. The `INTERNAL` label is greppable on purpose — the publish step checks for it.
- **The markdown file is the only artifact.** A second rendering drifts from the first; an early run shipped an HTML page whose text no longer matched its own report.
- **The fetch ladder is ordered by faithfulness, then reach — do not collapse it.** A harness fetch tool answers a prompt against the page and hands back a paraphrase; nothing quotable survives, and a second question about the same page costs a second fetch. An extractor returns the page itself, to a file, which is what makes VERIFIED quoting and Wayback diffing possible. But an extractor is not an unblocker — bot protection returns 403 to all of it, and `--user-agent` does not change that (tested) — so the lower rungs and the coverage gap stay exactly where they are. Measured 2026-09-08: a Wayback snapshot 834 KB → 14.9 KB and a Greenhouse board 69.6 KB → 5.6 KB, both clean; G2 returned 403 to the extractor exactly as it does to everything else.

Source of truth: `SKILL.md` in this directory, plus `references/report-template.md`, which is the report contract — read it before researching, not after. The YAML frontmatter (`description`) controls when either harness invokes the skill — keep it trigger-only (symptoms and situations, not workflow), or agents will perform the description instead of reading the skill.

## Pairs well with the shipping loop (optional)

Unlike `/grill` → `/ship` → `/wrap-up`, this one isn't part of the code loop — it's research, and it stands alone. It overlaps at one point: when the output directory is a git repo, the run commits per that repo's rules and leaves the push to you on anything shared.

## Feedback

This is v1. Expect to tune it. Edits to `SKILL.md` take effect next session.
