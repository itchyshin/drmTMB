# Florence visual audit: `capability-and-limits`

Scope: source-level audit of `vignettes/capability-and-limits.Rmd` and its two
generated Markdown includes. No sources were changed. The designated audit
render and figure directories existed but were empty at inspection, so there is
no rendered evidence that any table fits, scrolls accessibly, or retains its
semantic header structure in the published vignette. This is consequently a
source audit, not a completed visual check.

## Inventory

| Surface | Source | Intended estimand / data grain | Uncertainty or status claim | Visual assessment |
|---|---|---|---|---|
| At-a-glance table | `vignettes/capability-and-limits.Rmd:66-85` | One deliberately selected model/effect capability class per row; editorial summary, not observations or simulation replicates | Tier and the type of claim a reader may make (point, interval, or neither) | A useful decision aid, but 20 dense rows and sentence-length cells make the comparison hierarchy weak; no table caption identifies its scope or source. |
| Missing-response board | `vignettes/capability-and-limits.Rmd:421-430`; `vignettes/includes/capability-ledger-missing-response.md:1-22` | 18 response-family ledger rows | G3 is recovery-or-higher; G4/G5 are explicitly outside the arc | Correctly keeps status separate from inference tier, but the tick is repeated in every row and is not a sufficient visual encoding on its own. |
| Missing-predictor table | `vignettes/capability-and-limits.Rmd:435-439` | Three grouped response-family categories | Availability/rejection, not inferential uncertainty | Compact enough for ordinary reading, but uses ✓ and — without a legend in the table itself. |
| Full per-family capability map | `vignettes/capability-and-limits.Rmd:462-474`; `vignettes/includes/capability-ledger-family-map.md:1-20` | 18 family-level rows by nine capability dimensions; each cell aggregates many subroutes | Highest evidence is a selected exact-scope ledger status; missingness columns give G3 route status, not interval evidence | Too wide and text-heavy for a static Markdown table. It is an exhaustive lookup object, not a visually scannable comparison. |

There are no figure chunks, plotted estimates, ribbons, raw observations, or
simulation-replicate marks in this vignette. The article makes numerical
coverage statements in prose (for example, `Rmd:123-144`, `208-223`, and
`231-266`), but it does not visually display those results. Thus no figure
currently risks showing the wrong data grain; equally, a reader cannot inspect
the uncertainty evidence visually.

## Prioritized fixes

### P1 — Full capability map is not a usable public comparison at normal or mobile widths

**Evidence.** The rendered page injects a 10-column Markdown table
(`Rmd:469-474`) whose individual rows contain long, semicolon-delimited
route inventories and multiple internal status words
(`includes/capability-ledger-family-map.md:1-20`). Markdown alone supplies no
responsive wrapper, sticky key column, concise labels, or progressive
disclosure. The prose calls it a whole-package view (`Rmd:464-467`), so this
is the main reader-facing comparison rather than optional detail.

**Reader risk.** On a narrow screen, readers must horizontally pan while
holding the response-family name and the header mapping in memory; on a wide
screen, the text density obscures the distinction between implemented,
scope-limited, rejected, and the *highest-evidence* column. This invites the
exact over-reading the vignette otherwise works hard to prevent.

**Safe repair.** Keep the generated ledger authoritative, but replace the
public table with a compact capability matrix (short status tokens plus an
adjacent text legend) and a linked/downloadable detailed ledger. If the full
table stays, wrap it in an explicitly labelled, keyboard-scrollable container
with a visible scroll cue and a frozen first column; render and inspect desktop
and mobile evidence before accepting it.

### P1 — The page has no rendered visual evidence, so figure/table accessibility is unverified

**Evidence.** The source injects external Markdown through `cat(readLines())`
at `Rmd:425-430` and `469-474`. At audit time,
`docs/dev-log/release-audits/2026-07-21-site-audit/renders/capability-and-limits/`
and `.../figures/capability-and-limits/` were empty.

**Reader risk.** Source inspection cannot establish HTML table semantics,
wrapping, clipping, horizontal-scroll affordance, colour/tick contrast, or
whether the included Markdown survived rendering. The figure-audit hard gate
therefore prevents a publication-quality verdict.

**Safe repair.** Render the vignette, archive the HTML and screenshots of each
table at desktop and a phone width, and inspect them individually. This is a
documentation/figure-only validation step; it does not require likelihood or
simulation changes.

### P2 — Status glyphs are semantically underspecified and duplicate prose

**Evidence.** The missing-response board displays `G3 ✓` in every evidence
cell (`includes/capability-ledger-missing-response.md:3-20`), with the meaning
only in a trailing sentence (`:22`); the missing-predictor table uses ✓ and —
(`Rmd:435-439`) without a local legend.

**Reader risk.** A colour-blind or screen-reader user cannot safely infer that
the tick means *G3 recovery*, not interval coverage, particularly because the
article distinguishes these concepts immediately before the table
(`Rmd:421-423`) and has four inference tiers (`Rmd:31-62`).

**Safe repair.** Use explicit cell text such as “G3 recovery verified” and
“Rejected”, retain symbols only as redundant decoration, and place a concise
legend/caption immediately before the relevant table. Preserve the existing
sentence that G3 does not upgrade inference tier.

### P2 — The uncertainty narrative has no visual anchor, but a Confidence Eye is not appropriate here

**Evidence.** The article provides multiple coverage ranges and caveats in
prose (`Rmd:123-144`, `208-223`, `231-266`) and directs interval selection by
evidence channel (`Rmd:476-496`), without any estimate/interval display.

**Assessment.** The Confidence Eye convention is **not suitable for the
current tables**: their values are categorical capability states, not a common
estimand with an estimate and finite interval. Adding hollow circles and
compatibility regions would falsely imply row-wise numerical estimates and
comparability.

**Safe repair.** If a later compact evidence figure is desired, use a
simulation-summary display: one mark per campaign cell for empirical coverage,
a named binomial Monte Carlo interval, a nominal-coverage reference, and an
explicit marker for excluded/boundary-heavy cells. It must show the
replicate/campaign-cell grain, not reconstructed pseudo-replicates. Keep the
current prose-only treatment until such a plot can be rendered and checked.

### P3 — Captions and accessible table names are weak or absent

**Evidence.** The three summary tables begin directly after prose
(`Rmd:66-85`, `435-439`, and `469-474`); the generated missing-response table
is similarly inserted without a caption (`Rmd:425-430`).

**Reader risk.** Table purpose, scope, data source, and status meaning are not
available as a compact unit when a reader enters through search, assistive
technology, or a copied table.

**Safe repair.** Give every table a short descriptive caption/heading that
states its grain and one-sentence scope, e.g., “Table: response-missingness
validation status for 18 fitted response families; G3 denotes recovery, not
interval coverage.” Native HTML table captions are preferable if the vignette
renderer permits them.

## What is already scientifically honest

The prose is unusually careful about what uncertainty does *not* establish:
it separates point recovery, interval calibration, diagnostic-only routes, and
rejection (`Rmd:31-62`), states discrete simulation domains rather than
extrapolating them (`Rmd:135-144`), and preserves the zero-one-beta generator
caveat (`Rmd:247-266`). No raw-response display is expected for SD, correlation,
or coverage claims here; a future plot should show simulation or campaign-cell
results rather than raw data.

## Close

**Verdict:** not yet publication-ready as a visual capability page: the
scientific wording is honest, but the principal comparison is too dense and
unrendered. **Findings:** P1 = 2, P2 = 2, P3 = 1. **Docs/figure-only repair
safe:** yes; no likelihood-code, estimator, or simulation-artifact change is
needed for the scoped repairs, although a new empirical-coverage plot would
need its own rendered-evidence review.
