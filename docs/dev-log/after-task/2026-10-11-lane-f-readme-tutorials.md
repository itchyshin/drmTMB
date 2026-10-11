# README and tutorial-vignette reader fixes (lane F)

## Goal

Make the first screen of the README and the getting-started vignette answer
the questions an applied ecologist who already knows `lme4` or `glmmTMB` asks
first: how do I run one model, what does the output say, which word names
which parameter, and how does this map to what I already use. Also close
reader-facing gaps in the tutorial articles: a stale cross-reference, an
unexplained persona name, repository-only design-note paths, an incomplete
dependency sentence, a vignette sentence that overstated its own fitted value,
a missing classic `sleepstudy` twin, a missing Windows caveat for
`parallel = "multicore"`, and one-way links between `drmTMB` articles and their
DRModels.jl companion pages.

## Implemented

`README.md` now opens with the pitch, then one runnable location-scale example
with its equation, named symbols, and trimmed real output from `check_drm()`
and `summary()`. The duplicated "Tiny example" block is gone. A five-row
parameter-name table (formula name, plain-English name, meaning), an
"If you already use lme4 or glmmTMB" section mapping `dispformula` to
`sigma ~`, and a link to the comparison article follow. The install section
lists every `Imports` package and says that the GitHub install does not build
vignettes. The status table now names families and forms in each cell, drawn
from the model map. "Current boundaries" is split into one topic per paragraph,
with ML versus REML under its own heading.

`vignettes/drmTMB.Rmd` drops the install block (keeping the version sentence),
adds the parameter-name table and the `glmmTMB` bridge, prints and reads
`summary(fit)`, compares estimates with the simulated values, and puts the
`check_drm()` reading guide next to its first output. The example now uses
`set.seed(1)` instead of `set.seed(13)`: across seeds 1 to 200 of the same
simulation, the seed-13 `sigma` contrast (0.17, SE 0.13, truth 0.45) sat at the
1.5th percentile and its 95% Wald interval missed the truth; seed 1 gives
estimates within one standard error of every simulated value. The estimand
sentence is now a four-item list, `sd()` and "estimand" are glossed at first
use, the correlation paragraph is split, and the stale "Learning path table
above" reference names the real table.

`vignettes/location-scale.Rmd` computes the SD and variance ratios inline from
the fit (1.89 and 3.6 for seed 42), states the simulated truth (1.73 and 3.0),
and adds a Wald interval table for both ratios. The "Pat" sentence now says
"a reader". `vignettes/comparing-with-other-packages.Rmd` adds the classic
`Reaction ~ Days + (Days | Subject)` REML fit beside `lme4::lmer()`; fixed
effects, SDs, correlation, residual SD, and REML log-likelihood (-871.8141)
agree. `vignettes/large-data.Rmd` states that Windows aborts on
`parallel = "multicore"` and shows the serial call. `formula-grammar.Rmd` and
the generated capability-ledger summary now link design notes by GitHub URL.
Eighteen articles with a DRModels.jl twin end with one consistent companion
link; the getting-started vignette links the DRModels.jl first-model and
vocabulary pages.

## Files Changed

`README.md`; `vignettes/drmTMB.Rmd`, `location-scale.Rmd`,
`location-scale-scale.Rmd`, `comparing-with-other-packages.Rmd`,
`large-data.Rmd`, `formula-grammar.Rmd`, `robust-student.Rmd`,
`count-nbinom2.Rmd`, `proportion-beta-binomial.Rmd`, `bivariate-coscale.Rmd`,
`bivariate-nongaussian.Rmd`, `meta-analysis.Rmd`, `structural-dependence.Rmd`,
`animal-models.Rmd`, `phylogenetic-models.Rmd`, `relmat-known-matrices.Rmd`,
`which-scale.Rmd`, `convergence.Rmd`, `distribution-families.Rmd`,
`model-selection.Rmd`, `model-map.Rmd`, `articles/model-workflow.Rmd`;
`tools/capability_ledger.py` and its three regenerated outputs
(`vignettes/includes/capability-ledger-summary.md`,
`docs/dev-log/dashboard/capability-surface.md`, `.html`); this report and its
check-log row.

## Checks Run

Every changed vignette rendered with `rmarkdown::render()` against an installed
build of this branch. `tools/check-reader-contracts.R` reported OK.
`python3 tools/capability_ledger.py --check` and its 80 unit tests passed.
A spelling diff against `main` adds only `brms` and `Bürkner` (the spelling
test is report-only; `inst/WORDLIST` was left untouched to avoid cross-lane
conflicts). The full `testthat` suite result is recorded in the PR.

## Tests Of The Tests

The README output block, the vignette seed choice, the location-scale ratios,
and the `sleepstudy` agreement were all produced by running the code, not
written by hand. The DRModels.jl companion URLs were checked against the
`stable/` tree of the DRModels.jl `gh-pages` branch: every linked page exists.

## Consistency Audit

Terms follow `AGENTS.md`: `sigma`, `rho12`, `meta_V(V = V)`, and location,
scale, shape, and coscale defined at first use, with coscale tied to `rho12`.
No issue numbers, persona names, or dev-log paths were added to reader pages.

## What Did Not Go Smoothly

The README output block is pasted text because the repository keeps
`README.md` without a `README.Rmd`; it can drift if `summary()` printing
changes. Spatial articles (`spatial-models.Rmd`, `phylogenetic-spatial.Rmd`)
belong to the reference-docs lane, so their companion links are left for it.

## Team Learning

A seeded tutorial example should be checked against a seed sweep before prose
compares estimates with the truth; a 1.5th-percentile draw makes a correct
estimator look broken on the first page a user reads.

## Design-document Updates

None: no grammar, likelihood, family, or API change.

## pkgdown/documentation Updates

README (pkgdown home page) and the articles listed above.

## Known Limitations and Next Actions

Aligning the first examples of `drmTMB` and DRModels.jl on identical data, and
adding sleepstudy-style classic twins for Orthodont, Rail, Dyestuff, Pastes,
and grouseticks, are left for an owner decision.
