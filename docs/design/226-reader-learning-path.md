# 226 — One canonical reader learning path across 34 vignettes

## 1. The problem

`_pkgdown.yml` carries two independent taxonomies over the same 34 vignettes:
the navbar (`model_guides` 11 · `tutorials` 15 · `diagnostics` 4 · `developer`
3) and the `articles:` index used to render the pkgdown homepage grid
(`Getting Started` 1 · `Start Here` 4 · `Choose Your Model` 6 · `Applied
Family Tutorials` 3 · `Structured Dependence` 7 · `Inference, Diagnostics,
and Figures` 6 · `Simulation and Validation` 3 · `Developer Notes` 3). They
disagree on the placement of many articles. `drmTMB` (the getting-started
vignette) is a navbar Tutorial but an articles-index Getting-Started page.
`capability-and-limits` is a navbar Model Guide but an articles-index
Start-Here page. `convergence`, `large-data`, `julia-engine`, and
`cross-family` are navbar Model Guides but articles-index Inference /
Diagnostics / Figures pages. `implementation-map` and `testing-likelihoods`
are navbar Diagnostics but articles-index Simulation and Validation. Only 7
articles agree across both: `adding-families`, `count-nbinom2`,
`figure-gallery`, `formula-grammar`, `proportion-beta-binomial`,
`robust-student`, `source-map`.

A reader landing on the pkgdown site sees one order in the top navbar and a
different order on the homepage card grid. Neither order states a family-
choice stage explicitly, so a reader who arrives with count or proportion
data — the common case, not the Gaussian exception — has no signposted route
from "I have data" to "which family do I use." Two further reader paths exist
and disagree with both taxonomies and with each other: the "Learning path"
table inside `vignettes/drmTMB.Rmd:106-142`, and the six-step instructor
sequence in `docs/course/README.md:8-27`. Nine vignettes have zero inbound
links from any other vignette (`adding-families`, `convergence`,
`cross-family`, `distributional-outputs-and-adequacy`, `large-data`,
`model-selection`, `simulation-plot-grammar`, `source-map`,
`testing-likelihoods`); eight of those nine have no outbound links either,
so they are reachable only by guessing a URL or scrolling the reference
index.

## 2. The canonical sequence

Six stages, in reader order. Each stage answers one question the reader has
at that point in the workflow.

1. **First fit** — "How do I get a model running and check that it worked?"
   The reader has data and a question; they need the shortest path to a
   fitted object and a passing diagnostic check.
2. **Choose your family** — "Which distribution and which scale should I
   model — mean only, or mean and residual variance?" The reader's response
   is continuous, a count, a proportion, or paired; they need to pick a
   family and understand which parameter (`mu`, `sigma`, `nu`, `zi`, `hu`)
   they are about to specify.
3. **Interpretation tutorials (location / scale / shape / coscale)** — "Now
   that I picked a family, how do I write the formula, fit it, and read the
   coefficients?" Worked, biologically-motivated examples for each family
   and each parameter role, plus the family-specific applied
   tutorials.
4. **Random effects and structured effects** — "My observations are grouped,
   related, or spatially/phylogenetically structured — how do I model that
   dependence?" Structured random-effect syntax across `animal()`,
   `phylo()`, `spatial()`, `relmat()`, and the two-tree interaction case.
5. **Uncertainty, diagnostics, and inference boundaries** — "Is this fit
   trustworthy, is the distribution adequate, which comparisons can I make,
   and what should I do if it does not converge or the data are large?"
   Model selection, distributional adequacy, convergence, and large-data
   practice. Four pages, one question. Per §9.2 the Julia engine and
   cross-family routes do **not** belong here — they are an alternative
   compute backend, not a trustworthiness question.
6. **Honest limitations** — "What does this package NOT support yet, and
   where is the line between fitted, first-slice, and planned syntax?"
   `capability-and-limits` closes the arc; it is deliberately last, not
   first, because it opens with sobering material that would discourage a
   reader who has not yet fit anything.

A **Specialist branch** sits alongside stage 3 for three pages that are
deliberately off the main line: `meta-analysis`, which uses known sampling
variances and no raw response data — a different task from picking a family
for raw data — and, per §9.2, `julia-engine` and `cross-family`, which choose
a different compute backend rather than answering a modelling question. A
**Developer track** sits outside the reader path entirely, for the five pages
that document the package's own internals rather than how to use it.

## 3. The full placement table

34 rows. Role legend: **tutorial** = worked biological example with fitted
output and interpretation; **guide** = orientation/reference, no full worked
analysis; **route-chooser** = helps the reader pick a family or syntax
before fitting; **specialist** = correct placement is deliberately outside
the main line; **developer** = internals audience, not the applied reader
path.

| # | Vignette | Stage | Role | Reason |
|---|---|---|---|---|
| 1 | `drmTMB` | 1. First fit | tutorial | Fits the first Gaussian location-scale model, runs `check_drm()`, is the front door every other stage is reached from. |
| 1a | `function-map-cheatsheet` | 1. First fit | guide | A searchable function router and compact workflow for readers who know their question but need the smallest useful `drmTMB` sequence before the longer model-workflow guide. |
| 2 | `model-workflow` | 1. First fit | guide | Post-fit checklist (`check_drm()`, `profile_targets()`, `conf.status`, prediction, residuals, simulation) a reader needs immediately after the first fit, before touching family choice. |
| 3 | `which-scale` | 2. Choose your family | route-chooser | Disambiguates residual `sigma`, `sd(group)`, likelihood weights, and known sampling variance before the reader picks a family — answers "which scale am I even modelling" ahead of "which family." |
| 4 | `distribution-families` | 2. Choose your family | route-chooser | Direct family-selection guide: continuous, count, proportion, robust — the question stage 2 exists to answer. |
| 5 | `model-map` | 2. Choose your family | route-chooser | "What can I fit today?" status map; the reader consults it while deciding which family/syntax combination is actually implemented. |
| 6 | `location-scale` | 3. Interpretation tutorials | tutorial | Flagship Gaussian location-scale worked tutorial: `mu` and `sigma` interpretation with a biological example. |
| 7 | `robust-student` | 3. Interpretation tutorials | tutorial | Student-t shape-parameter (`nu`) worked tutorial for robust continuous responses. |
| 8 | `count-nbinom2` | 3. Interpretation tutorials | tutorial | NB2 count worked tutorial, including zero-inflation (`zi`). |
| 9 | `proportion-beta-binomial` | 3. Interpretation tutorials | tutorial | Beta, beta-binomial, and zero-one-beta worked tutorial for bounded/proportion responses. |
| 10 | `bivariate-coscale` | 3. Interpretation tutorials | tutorial | `rho12` residual-coupling worked tutorial — the coscale interpretation case named in the target order. |
| 11 | `missing-data` | 3. Interpretation tutorials | guide | Documents `miss_control()` response/predictor routes; a reader needs this while writing the formula for their chosen family, not after fitting, so it sits with the family/formula-writing stage rather than stage 5. |
| 12 | `meta-analysis` | Specialist branch | specialist | Per P2: known sampling variances with no raw data is categorically unlike choosing a family for raw observations. Kept `family = gaussian()` plus `meta_V(V = V)`, clearly labelled as a specialist route, not folded into "Choose your family." |
| 13 | `structural-dependence` | 4. Random & structured effects | route-chooser | Overview and router across `animal()`, `phylo()`, `spatial()`, `relmat()` before the reader picks a specific structured-effect tutorial. |
| 14 | `animal-models` | 4. Random & structured effects | tutorial | Worked `animal()` / additive-relatedness tutorial. |
| 15 | `phylogenetic-models` | 4. Random & structured effects | tutorial | Worked `phylo()` tutorial for phylogenetic mixed models. |
| 16 | `bipartite-phylogenetic-interactions` | 4. Random & structured effects | tutorial | Worked two-tree `phylo_interaction()` tutorial. |
| 17 | `spatial-models` | 4. Random & structured effects | tutorial | Worked `spatial()` coordinate-structured tutorial. |
| 18 | `relmat-known-matrices` | 4. Random & structured effects | tutorial | Worked `relmat()` known-matrix tutorial. |
| 19 | `phylogenetic-spatial` | 4. Random & structured effects | guide | Deeper structural-dependence detail page (three-step ladder, q=2/q=4 status); companion detail to `structural-dependence`, read after the individual worked tutorials. Not split per Non-goals. |
| 20 | `model-selection` | 5. Uncertainty & inference boundaries | guide | AIC/BIC model comparison; per P8 this sits after random/structured effects (the reader now has candidate models worth comparing) and before general uncertainty/diagnostics material. |
| 21 | `distributional-outputs-and-adequacy` | 5. Uncertainty & inference boundaries | tutorial | Promoted per F1: only vignette demonstrating `worm_plot()`, `qq_plot()`, `centile_chart()` — three of the package's six public plotting functions. Belongs in the diagnostics/adequacy stage, well linked, not left disconnected. |
| 22 | `convergence` | 5. Uncertainty & inference boundaries | guide | Optimizer diagnostic table (`optimizer_convergence`, `optimizer_budget`, `fixed_gradient`) — a trustworthiness question, read once the reader has fits worth diagnosing. |
| 23 | `large-data` | 5. Uncertainty & inference boundaries | guide | `keep_data`, `keep_model_frame`, `se = FALSE` practice for scaling up — an inference-boundary/practical-limits question. |
| 24 | `julia-engine` | Specialist branch | guide | **Corrected in §9.** An alternative compute backend, not a trustworthiness question. Self-described "for R users, contributors, and early testers"; a count-data reader has no reason to pass through it. |
| 25 | `cross-family` | Specialist branch | tutorial | **Corrected in §9.** Experimental Julia-engine route needing a DRM.jl checkout; follows `julia-engine`, both outside the main line. |
| 26 | `figure-gallery` | 3. Interpretation tutorials | tutorial | **Corrected in §9.** Family-agnostic plotting recipes answering "how do I show my result?" — a question the reader has while interpreting coefficients, not after diagnostics. Was stranded behind two experimental-engine pages. |
| 27 | `capability-and-limits` | 6. Honest limitations | route-chooser | Per P7, stays LAST. Opens with sobering multi-seed-evidence and boundary material that would discourage a reader who has not yet fit anything; correct as the closing "what this package will not yet do" page. |
| 28 | `formula-grammar` | Developer track | developer | Formula-parsing internals for contributors adding syntax, not for the applied reader path. |
| 29 | `adding-families` | Developer track | developer | Contributor guide for adding a new distribution family to the C++/R engine. |
| 30 | `source-map` | Developer track | developer | Maps R builders to TMB `model_type` integers and C++ density blocks — internals reference for contributors. |
| 31 | `testing-likelihoods` | Developer track | developer | Documents the likelihood-comparator test harness used to validate new families against reference implementations. |
| 32 | `implementation-map` | 2. Choose your family | guide | **Corrected in §9 — reverted to the applied path.** It opens "This map answers one practical question: what model surface can an applied user…", and `model-map` links to it from four places (`model-map.Rmd:38,53,152,157`). Reclassifying it developer-only would break live cross-links from an applied guide and hide the page readers are explicitly sent to. |
| 33 | `simulation-plot-grammar` | Developer track | developer | Bias/RMSE/coverage plotting conventions for simulation-based validation; used when writing or reviewing recovery studies, not when applying the package. |

Total: 34 placed. Stage counts **after the §9 corrections**: **1. First fit**
= 3 · **2. Choose your family** = 4 · **3. Interpretation tutorials** = 7 ·
**Specialist branch** = 3 · **4. Random & structured effects** = 7 ·
**5. Uncertainty & inference boundaries** = 4 · **6. Honest limitations** = 1
· **Developer track** = 5.
3 + 4 + 7 + 3 + 7 + 4 + 1 + 5 = 34.

Two rows deserve a placement note beyond the reason column:

- **`implementation-map` and `simulation-plot-grammar`** moved out of the
  navbar's "Diagnostics & Validation" menu and the articles-index "Simulation
  and Validation" group into the Developer track. Both pages are aimed at
  someone building or auditing a new family/simulation (slice ledgers, bias/
  RMSE/coverage plotting conventions for recovery studies), not at someone
  applying an already-implemented family to their data. `testing-likelihoods`
  is already developer-facing by its own content (a comparator test harness)
  and joins the same track, consistent with the brief's instruction that
  `testing-likelihoods` stays in the separate developer audience track.
- **`missing-data`** placed in stage 3 rather than stage 5. Its content
  (`miss_control()` response/predictor routes) is something the reader
  decides while writing the formula for their chosen family — before
  fitting — not a post-fit inference-boundary question. This is the one
  placement that is genuinely arguable; see §8.

## 4. What changes in `_pkgdown.yml`

**Target: collapse to one taxonomy.** Recommendation: delete the
navbar/`articles:` split as two independently-curated lists and drive both
from a single ordered stage list, expressed twice only because pkgdown
requires it (navbar menu items and the `articles:` index are separate YAML
structures with no shared-source mechanism) — not because they should ever
be curated separately again.

Concrete target:

- **Navbar** — rename the four menus to match the six stages plus the two
  branches, in stage order: `Get Started` (stage 1), `Choose Your Family`
  (stage 2 + specialist branch, meta-analysis listed as a clearly-labelled
  "Specialist: known-variance data" sub-entry), `Tutorials` (stage 3 family
  tutorials + stage 4 structured-effect tutorials, in that order),
  `Diagnostics & Inference` (stage 5), and keep `Developer Notes` as-is
  (stage's Developer track, unchanged membership except adding
  `implementation-map` and `simulation-plot-grammar`, which are already
  there in spirit — see §3). `capability-and-limits` moves to the end of
  whichever menu holds it, or becomes its own single-item "Limitations"
  navbar entry so its terminal position is visible in the navbar itself, not
  just in reading order.
- **`articles:` index** — replace the eight existing group titles with the
  same six-plus-two set, same membership, same order, titled identically to
  the navbar menus (e.g. both say "Choose Your Family", not one "Model
  Guides" and the other "Choose Your Model").
- **The rule that keeps them from diverging again**: add a one-line HTML
  comment block at the top of both the `navbar:` and `articles:` sections in
  `_pkgdown.yml` pointing at this file — `# canonical order: docs/design/226-reader-learning-path.md
  — keep navbar menu membership and articles: group membership identical to
  §3's stage column` — and add a cheap CI/local check (a short R or shell
  script comparing the set of `href`/`contents` entries per matching
  menu/group name) to `docs/design/` tooling or a Makefile target, run
  before `pkgdown::build_site()`. This review's job is the design, not the
  script; flagging the concrete check to add is in scope, writing it is not
  (Non-goals, §7).

## 5. The three other reader paths

- **`vignettes/drmTMB.Rmd`'s "Learning path" table (lines 106-142)**
  *becomes the canonical narrative.* It is the first page every reader
  hits, and its per-question table format ("If your question is... read
  this first... main parameter") is the right *mechanism* for the canonical
  order — it just needs its rows re-sequenced and completed to match §2/§3
  exactly: add the missing family-choice framing explicitly ("Which family
  fits my response?" → `distribution-families`), keep `meta-analysis` but
  label it as a specialist route in the same row it already occupies, and
  add the stage-5/stage-6 rows it currently omits (`model-selection`,
  `convergence`, `large-data`, `julia-engine`, `cross-family`,
  `distributional-outputs-and-adequacy`, `capability-and-limits`) so the
  in-page table and the site-wide order tell one story.
- **`docs/course/README.md`** *stays unchanged in structure.* Per P6, do not
  restructure its six-step instructor sequence or its instructor-facing step
  6. The only permitted change is terminology/link parity: its prose already
  matches the target vocabulary (`sigma`, `sd(group)`, `rho12`,
  `meta_V(V = V)`) and already sequences location-scale before structural
  dependence before implementation/source maps, which is compatible with
  the canonical stage order — no wording or step change is needed here at
  all. State this explicitly so no later editor "helpfully" reorders it to
  literally mirror §2.
- **The `reference:` index** (function reference, `_pkgdown.yml:106-198`)
  *is unchanged.* It is organized by object kind (formula constructors,
  structured-effect markers, fitting/post-fit tools, distributional
  outputs, Julia engine, visualization), which is a different and correct
  organizing principle for a function reference. This design note is about
  vignette reading order, not the function index; no change proposed.

## 6. Orphan resolution

For each of the 9 zero-inbound vignettes, the specific article that should
link to it and the reader moment the link serves:

1. **`adding-families`** — `formula-grammar` should link to it when a
   reader's formula question turns out to be "this family doesn't exist
   yet" rather than a syntax question; both are developer-track pages, and
   `formula-grammar` is the more likely entry point for a contributor.
2. **`convergence`** — `model-workflow` should link to it at the
   `check_drm()` step, for the moment a reader's `check_drm()` output flags
   `optimizer_convergence` or `fixed_gradient` problems and they need the
   full diagnostic table, not just the summary check.
3. **`cross-family`** — `julia-engine` should link to it once the reader
   has confirmed `engine = "julia"` runs, for the moment they ask "now that
   the bridge works, what can I fit that the default engine can't" — the
   cross-family bivariate route.
4. **`distributional-outputs-and-adequacy`** — `model-workflow` should link
   to it right after the `check_drm()` step, for the moment a reader asks
   whether the fitted distribution itself is adequate (worm/QQ plots,
   centiles), not just whether the optimizer converged.
5. **`large-data`** — `model-workflow` should link to it when a reader's fit
   is slow or memory-heavy, for the moment they ask "how do I keep fitting
   this at scale" after the standard post-fit workflow starts choking on
   size.
6. **`model-selection`** — `model-workflow` should link to it once a reader
   has more than one candidate fit (e.g., after adding a `sigma` covariate),
   for the moment they ask "which of my two fitted models should I report."
7. **`simulation-plot-grammar`** — `implementation-map` should link to it,
   for the moment a contributor reading the implementation ledger asks "how
   do I plot the recovery evidence for a slice I'm about to close out."
8. **`source-map`** — already has 4 real inbound mentions in the current
   corpus (`count-nbinom2`, `figure-gallery`, `implementation-map`,
   `proportion-beta-binomial`) but per the brief's VERIFIED figures it
   registers as zero-inbound in the checked link graph; confirm at
   implementation time whether those are live `.html` links (the earlier
   grep in this review's own working notes found no `source-map.html`
   href, only the bare word "source-map" in prose) — if they are prose
   mentions without a markdown link, `implementation-map` is still the
   right anchor: link to it for the moment a contributor asks "where in the
   C++/R code does this `model_type` actually live."
9. **`testing-likelihoods`** — `adding-families` should link to it for the
   moment a contributor has written a new family and asks "how do I check
   my density against a reference implementation before shipping it."

## 7. Non-goals

- No split of `structural-dependence` or `phylogenetic-spatial.Rmd` into
  smaller articles. Both stay as single pages; §3 places
  `phylogenetic-spatial` as a companion detail page to `structural-dependence`,
  not as a reason to fragment either.
- No restructuring of `docs/course/README.md`'s six-step sequence (§5).
- No new plotting helpers, functions, or exports. This note does not add to
  the six public plotting functions named in §3 row 21.
- No capability claims restated by hand. Where this note references what is
  fitted, first-slice, or planned, it points to `model-map` or
  `capability-and-limits` as the authority rather than asserting status
  itself (see §3 rows 5 and 27).
- No functionality change of any kind — this is a reading-order and
  `_pkgdown.yml` grouping design only. No vignette content, `_pkgdown.yml`
  entries, or R code are edited by this note itself; §4's concrete target is
  a specification for a follow-on slice to implement.

## 8. Ambiguous placement, flagged rather than silently resolved

`missing-data` is the one row in §3 without a clean single answer.
`miss_control()` is formula-adjacent (a reader sets it while specifying the
model for their chosen family, which argues for stage 3, where this note
places it) but it is also arguably an inference-boundary concern (which rows
get dropped or retained changes what the fit can say, which argues for
stage 5, alongside `convergence` and `large-data`). This note places it in
stage 3 because the decision happens before fitting, not after — but a
future editor with stronger evidence about where readers actually get stuck
should feel free to move it to stage 5 without re-litigating the rest of
this table.

## 9. Sequence-review corrections (binding)

Pat (applied reader) and Darwin (ecology/evolution audience) reviewed §2–§8
before any prose was written. Both returned blocking findings. The claims
below were verified directly against the repository before being adopted; the
placement table above already reflects them.

### 9.1 `implementation-map` returns to the applied path — REVERTED

The original table moved it to the Developer track. That was wrong on two
checked counts:

- it opens *"This map answers one practical question: what model surface can
  an applied user…"* — it self-describes as applied-reader material;
- `model-map` — a stage-2 page firmly on the applied path — links to it from
  **four** places (`model-map.Rmd:38,53,152,157`), including two rows of its
  own routing table.

Reclassifying it developer-only would have broken live cross-links from an
applied guide and hidden the page a reader building a structured model is
explicitly told to consult next. It is placed in stage 2 beside `model-map`.

`simulation-plot-grammar` stays in the Developer track: it is fully
disconnected (zero inbound and zero outbound links), so nothing breaks, and
its content — bias/RMSE/coverage plotting conventions for recovery studies —
is written for someone auditing a simulation, not applying the package.

### 9.2 Stage 5 was a dumping ground — split

Both reviewers independently reached this. `julia-engine` and `cross-family`
are an alternative compute backend, not a trustworthiness question;
`julia-engine` addresses "R users, contributors, and early testers" and
`cross-family` needs a DRM.jl checkout. A reader with count data was being
routed through both between core diagnostics and the closing pages, which
reads as required and is not.

They join the specialist branch. Stage 5 keeps the four pages that answer one
question — *is this fit trustworthy?* — `model-selection`,
`distributional-outputs-and-adequacy`, `convergence`, `large-data`.

### 9.3 `figure-gallery` moves to stage 3

"How do I show my result?" is a question the reader has while interpreting
coefficients, not after diagnostics. It was stranded behind two experimental-
engine pages. Moving it also puts it beside the tutorials whose examples the
companion figure PR will reuse.

### 9.4 `model-workflow` stays in stage 1 — with a signpost, not a split

Pat is right that it is not a checklist: at ~1,000 lines it fits
`(1 | site)` early and later builds `sd(site) ~ reef_cover` surfaces and
`emmeans` marginal means — stage-3/4 material under a stage-1 label.

Splitting it is **out of scope** (§7 non-goals: no article splits in this
arc). The prose pass instead adds an explicit internal signpost where the
article turns from post-fit basics to random-effect material, telling the
reader that section assumes stage-4 content and can be deferred. Recorded as
a follow-up candidate for a later arc, not silently left as-is.

### 9.5 Organism identity is inconsistent — recorded, not fixed here

Darwin found that the "one recurring growth scenario" does not exist. The
spine articles split by organism:

| Article | Implied organism |
|---|---|
| `drmTMB` | plants — forest / grassland |
| `location-scale` | plants — forest / grassland |
| `which-scale` | fish — population |
| `model-workflow` | fish — reef / kelp |

Unifying them onto one organism would mean renaming variables inside fitted
chunks, which changes the figures the companion figure PR depends on and
conflicts with the standing decision to **freeze** the example set to what
existing figures already use. This arc therefore does **not** rename
organisms. The prose pass instead states each article's scenario explicitly
and honestly as a distinct simulated scenario. Unification is recorded here
as a named follow-up.

Darwin's recommended target set, if that follow-up is taken: springtail
counts (`count-nbinom2`), germination trays (`proportion-beta-binomial`),
seedling growth under drought (`robust-student`, absorbing the spine growth
examples), behavioural-syndrome coupling (`bivariate-coscale`).

### 9.6 Two content gaps recorded, both out of scope here

- **Heritability is never computed in `animal-models`.** A single weak string
  match exists; no worked Va/Vp result. For an evolutionary biologist that is
  the entire point of an animal model. Adding it is a content change to a
  tutorial's statistical output, which needs its own evidence check — filed,
  not done here.
- **`distribution-families` leads with implementation status**, not
  biological reasoning, at exactly the moment the reader is choosing a
  family. The prose pass may reorder its opening so the response-type
  question comes first, but must not restate capability by hand — status
  stays sourced from `model-map` / `capability-and-limits`.

### 9.7 Settled

`missing-data` stays in stage 3. Both reviewers agreed: it is decided while
writing the formula for a chosen family, not diagnosed after fitting. §8's
open question is closed.
