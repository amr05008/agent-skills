# Teardown report spec (v2.5, 2026-10-05)

This is the report contract. Header, audience, structure, evidence labels, and verdict below are requirements, not suggestions. This file is the only copy. To run a teardown on a harness without the skill, generate a portable prompt from it at the time of use — do not create a second copy to keep in sync. A second copy was kept elsewhere until 2026-09-03; it drifted while claiming to be synced, which is why it is gone. A portable prompt must also carry `SKILL.md`'s Phase 2 fan-out rules — one level deep, no paid calls in a subagent, a blocked source is a finding — which live there and not here: a harness driven from this file alone is precisely where an unbounded fan-out runs unwatched.

## Framing and audience

Current as of the run date — live research only; if the web is unreachable, say so and stop rather than answering from training data. Prioritize evidence from the last 24 months; date-flag anything older.

Tailor the so-what to the stated **purpose** (operator diligence / potential partner / writing about the space / other) and write for the stated **audience**. One audience per file.

**`audience: me`** (default) — a strategy-analyst briefing for the caller. Calibrate it to their background using the `operator_profile` named in the house config, if there is one; with none, write for a senior product or strategy reader. §10's next moves are addressed to the caller or to the company, per purpose.

**`audience: team`** — the report a coworker at the org named in the purpose can read cold and forward. It is:
- Byline "Prepared by <byline> for <org>, <run date>", where <byline> comes from the house config and <org> is the recipient org named in the purpose and never the subject company. With no nameable org the byline is "Prepared by <byline>, <run date>" and the next moves address the reader. The byline names <org> only; a team named in the purpose appears in the Audience row and is who the next moves in §10, or the Assessment in page-signal mode, are addressed to.
- Free of the caller's private framing: no operator-profile references, no "why I'm looking", no side projects. (The operator profile may still be read to calibrate; it is never cited.)
- People by public role: names, titles, tenure, prior companies, labeled as usual. No contact fields — no emails, phones, or handles — and no enrichment-record dumps.
- Paid and enriched sources (Clay, LinkedIn via Monid) summarized and cited; a quote from a paid post is at most one sentence.
- Coverage gaps stated as what wasn't covered ("Reddit not searched"), not which internal tool was missing.
- Same evidence discipline, structure, verdict, and length band as `me`.

Filenames carry the audience: `me` reports are `YYYY-MM-DD-<slug>-teardown.md`, `team` reports `YYYY-MM-DD-<slug>-teardown-team.md` (page-signal likewise). To produce a `team` version of an existing `me` report, rerun Phase 4 only on the same research into the `-team` sibling, under the same collision rule; it gets its own artifact and the team pre-publish check applies.

## Header (required; first thing in the file)

No YAML frontmatter — the artifact viewer renders a leading `---` block as a heading made of the keys. In this order:

1. H1 title: `<Company> — Product & Business Teardown` (page-signal: `<Company> — Page Signal`).
2. Byline: `me` → "Analyst briefing for <byline>, <run date>"; `team` → "Prepared by <byline> for <org>, <run date>", or "Prepared by <byline>, <run date>" when no org is nameable.
3. The run table — exactly these five rows. Verdict and Page read `pending` until known and are filled last.
4. The evidence key: the three labels, one line each.
5. §1 begins.

Example run table. The `Field | Value` header row is required: a headerless `| | |` renders in the artifact viewer as an empty band above the first row (verified 2026-09-03).

| Field | Value |
|---|---|
| Audience | team (Acme — growth team) |
| Purpose | competitive diligence for Acme's growth team |
| Verdict | pending |
| Run | 2026-09-02 · claude code · claude-fable-5-1 |
| Page | pending |

Allowed values — Audience: `me`, or `team (<org>)`, or `team (<org> — <team>)` when the purpose names a team, or `team (recipient unnamed)`. Purpose: as stated, or the default plus "(defaulted)". Verdict: one of the four below, `n/a` for page-signal, or `pending`. Run: date · harness (`claude code`, `pi`, or the harness name) · model id. Page: the artifact URL, `none (<harness>)`, `publish failed (<reason>)`, or `pending`.

## Evidence discipline (every material claim)

- Direct link + date of the evidence.
- Exactly one label: **VERIFIED** (primary source seen directly) · **COMPANY-CLAIMED** (stated by the company, unaudited — press coverage of funding announcements counts as this, not as verified) · **ESTIMATE** (your triangulation, method shown) · **INTERNAL** (from the `incumbent_context` the house config named — see `SKILL.md` Phase 2 for where it may and may not appear).
- `INTERNAL` is not a strength claim. It says *where a claim came from*, not how sure you are of it: an internal roadmap states intent, and intent is not shipped product. Never let an `INTERNAL` claim about the incumbent do the work of a VERIFIED one about the subject, and never present a plan as a capability.
- Never invent revenue, growth, employee, customer, or funding figures. Private data → triangulate a range, show assumptions, label ESTIMATE.
- **A figure that reached you through a summarizing fetch is not VERIFIED — and does not go in the report at all until you have located it.** A summarizing fetch is any tool that hands back a model's prose *about* a page rather than the page's own bytes: `WebFetch` (the ladder's second rung), and any MCP "read this URL" tool that answers a question instead of returning the text. Marketing pages routinely render headline stats as client-side counters absent from the fetched text, and a summarizer asked for "the numbers" supplies plausible ones anyway. Before any quantified claim from such a fetch is written down:
  1. Look for the figure in the page's own text — the ladder's first rung (`defuddle`), or `curl` the URL. Found → VERIFIED, cite it.
  2. Absent there, that is the counter case, not a confirmation. Check the **rendered** page (Claude Code: Chrome MCP `get_page_text`). Found → VERIFIED.
  3. Still absent, or this harness has no rendered-page tool (Pi has none): **the claim is dropped.** Not downgraded to COMPANY-CLAIMED, not to ESTIMATE, and above all not kept as a contradiction against another source — a number no one can find is not evidence that the company contradicted itself. Record a coverage gap instead ("homepage stats render client-side; not verifiable from this harness") and move on. What dies is that unlocatable number, not the metric: an independent triangulation of the same quantity, method shown, is still a legitimate ESTIMATE.
  (2026-09-03: a summarizing fetch reported a homepage figure that exists nowhere in the DOM. Relabeling it COMPANY-CLAIMED would have shipped the same fabrication one label down, in a report addressed to a coworker's team — hence step 3.)

## Required research methods

- **Reconstruct history:** Wayback captures of homepage + pricing page across the company's life. Start from the CDX index's change points (`SKILL.md` Phase 2 gives the query), then read the captures on either side of each change: a pivot is dated by the last capture with the old copy and the first with the new. Removed or hidden pricing is a finding.
- **Mine job listings for content** — companies leak traction claims, org strategy, and comp bands in job-description copy.
- **Reconcile contradictions** between sources, including the company's own pages. A discrepancy is a finding, not noise.
- **Treat absence as evidence:** missing reviews, missing marquee customers, sentiment that goes quiet. Say what you looked for and did not find.

## Structure (full teardown)

1. **Executive summary** — what/who/why it matters; core thesis (win, lose, or niche); 3–5 most important findings
2. **Company snapshot** — founding, HQ, founders, leadership, ownership; headcount + hiring signals and trend; funding, investors, valuation, runway/profitability signals, acquisitions; revenue/ARR, growth, customer count, unit-economics signals. Include tech stack if enrichment provides it cheaply.
3. **Product and positioning** — description + key workflows; jobs-to-be-done; architecture/integrations/platform dependencies; the promise its messaging makes; the unique wedge (distribution, product insight, pricing, data, community, brand, partnerships, technical); is the wedge durable, and why
4. **ICP, users, and buying process** — primary/secondary ICPs; end user vs economic buyer vs champion vs blocker; size/industry/geo/maturity/trigger events; pains, outcomes, switching costs, objections, procurement; GTM motion (bottom-up, sales-led, enterprise, partner-led…)
5. **Pricing and business model** — tiers, packaging, limits, free/freemium, enterprise terms; pricing power + likely ACV/customer economics (ESTIMATE with method); monetization + expansion paths; comparison with major competitors
6. **Competitive landscape** — direct, adjacent, incumbents, and "do nothing / spreadsheets / build in-house"; comparison table (target customer, differentiator, pricing, distribution, strengths, weaknesses); identify the *real* competitive set, not the category listing; threats over 12–24 months
7. **Market and go-to-market** — category; market size only if defensible; tailwinds/headwinds; acquisition channels + distribution evidence; traction evidence (customers, case studies, usage, web/search signals, reviews, hiring, partnerships)
8. **Customer sentiment and public perception** — reviews from credible sources; note explicitly where no review corpus exists; repeated praise vs repeated complaints; volume, recency, selection bias; brand perception among buyers, users, observers
9. **Risks and weaknesses** — product, GTM, competition, platform, regulatory, financial, execution; assumptions that must be true; what evidence would falsify the bullish thesis
10. **Strategic assessment** — SWOT or equivalent; moat: what compounds with scale vs what's easily copied; the 3 highest-leverage next moves — addressed per audience (see Framing): to the company or to the caller for `me`, to the org for `team`; 12–24 month bull/base/bear outlook
11. **Open questions** — the decision-relevant unknowns + the fastest way to validate each

Clear headings, concise prose, tables where useful, source list at the end. Lead with conclusions, not a chronology of research. Target 3,000–5,000 words; depth over padding.

For Wayback-sourced claims, the evidence date is the capture timestamp of the page actually served — the one in the fetched `id_` URL, or the `Location` header when Wayback substituted a nearer capture — not the access date and not the timestamp you asked for.

## Verdict (required for full teardowns; strategic-direction mode ends with its Assessment instead)

One of, with the few variables that matter most:
- **compelling** — durable advantage and traction independently evidenced
- **promising but unproven** — real signals, but the defining bets are unresolved
- **structurally challenged** — the model or market works against them regardless of execution
- **unclear** — evidence too thin to take a position (use sparingly; say what's missing)

## Strategic-direction mode (landing-page analysis only)

When the subject is a specific landing/product page rather than the whole company, produce just:
- Page summary: URL, headline, target audience, offering, CTA, social proof (all VERIFIED from the page)
- Signal interpretation: what this says about strategic direction
- Relationship to core product: complement, extension, pivot, test, or land-grab
- Market opportunity targeted (defensible sizing only)
- Competitive implications: who should be worried
- Assessment: how credible is the entry, and what to watch

Same header, audience contract, and evidence discipline; ~800–1,500 words.
