# After Task: Phase 6b Slices 62-68 Tutorial Quality

## Goal

Carry the Phase 6b tutorial programme from the Slice 61 source map through the
landing path, major tutorial interpretation edits, random-effect scale
guardrails, and local gate.

## Implemented

- Slice 62: updated Getting Started and the model map so readers can move from
  a scientific phrase to the relevant guide, tutorial, or post-fit workflow.
- Slice 63: added a compact slope-interpretation table to the Gaussian
  location-scale tutorial, separating fixed mean slopes, fixed residual-scale
  slopes, random-slope SDs, residual-scale random-slope SDs, and
  random-effect scale slopes.
- Slice 64: added a bivariate coefficient-reading table for `mu1`, `mu2`,
  `sigma1`, `sigma2`, and `rho12` slopes.
- Slice 65: added a meta-analysis report-scale table for known sampling
  variance, fitted extra heterogeneity SD, heterogeneity variance, and total
  observation variance.
- Slice 66: added a six-row q=4 phylogenetic covariance interpretation table,
  including all four mean-scale pairs.
- Slice 67: added a Family A versus Family B section to the scale guide,
  including the current `sd_phylo()` spelling, the future
  `sd(..., level = ...)` idea, `corpairs()`, and invalid mixed formulations.
- Slice 68: ran the local docs gate and updated `ROADMAP.md` with the local
  gate boundary.

## Mathematical Contract

No fitted-model behavior changed. The tutorial layer now uses the Slice 61
contract:

```text
mu slope                 -> expected-response change
sigma slope              -> log residual-SD change
random-slope SD          -> among-group reaction-norm variation
sd(group) slope          -> predictor-dependent group-level mean-effect SD
rho12 slope              -> residual response-response coupling
corpairs row             -> fitted correlation layer named by level/class
```

The q=4 phylogenetic tutorial keeps all six latent covariance rows visible:
`mu1`-`mu2`, `mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`,
`mu2`-`sigma2`, and `sigma1`-`sigma2`.

## Files Changed

- `ROADMAP.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/model-workflow.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/meta-analysis.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-6b-slices-62-68-tutorial-quality.md`
- `docs/dev-log/after-phase/2026-05-15-phase-6b-tutorial-quality-closure.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/model-workflow.Rmd vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/bivariate-coscale.Rmd vignettes/meta-analysis.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `git diff --check`: passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed and rendered the touched articles plus `ROADMAP.html`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `rg -n "Question-first|If the scientific phrase|slope-like quantities|Family A versus Family B|Choose the report scale deliberately|Read the six q=4 rows|Done: Getting Started|Done locally" ROADMAP.md pkgdown-site/ROADMAP.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-map.html pkgdown-site/articles/model-workflow.html pkgdown-site/articles/location-scale.html pkgdown-site/articles/which-scale.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/meta-analysis.html pkgdown-site/articles/phylogenetic-spatial.html --glob '!pkgdown-site/search.json'`:
  confirmed source and rendered tutorial updates.
- `rg -n "phylogenetic slopes.*implemented|spatial slopes.*implemented|direct profile intervals for derived|q=4.*profile-ready|all six.*profile-ready|rho ~|meta_gaussian\\(|tau ~|Family A.*implemented.*Family B.*same" vignettes ROADMAP.md docs/design --glob '!docs/dev-log/**'`:
  found only intentional guardrail references for unsupported `meta_gaussian()`,
  `tau ~`, and planned structured-slope/status wording.

## Tests Of The Tests

No `devtools::test()` run was needed because this was documentation-only.
The executable validation was pkgdown rendering, pkgdown metadata checking,
formatting, whitespace checks, and stale-claim scans.

## Consistency Audit

The tutorial edits keep `rho12` as residual coupling, keep `sd(group)` and
`sd_phylo()` as direct-SD models rather than residual scale formulas, and keep
q=4 derived profile intervals unavailable. Spatial slopes and phylogenetic
slopes remain planned unless later implementation slices add code, tests,
`corpairs()` rows, and examples.

## What Did Not Go Smoothly

A direct `pkgdown::build_article()` loop failed on `model-workflow.Rmd` because
the local installed `drmTMB` package was older than the current source tree and
did not export `predict_parameters()`. The full `pkgdown::build_site()` gate
installs the current package into a temporary library first, and that rendered
the article successfully.

## Team Learning

- Ada: tutorial gates should record the local/rendered evidence and the PR-side
  GitHub Actions boundary separately.
- Jason: the source map paid off; each article edit could be tied to a named
  Phase 6b slice.
- Pat and Darwin: the new tables make the biological reading of slope and
  variance components less implicit.
- Noether: the key win is keeping the output scale beside the equation and R
  syntax.
- Rose: the stale-claim scan still matters because these docs sit next to
  planned structured slopes and derived interval language.

## Known Limitations

This task did not add new model behavior, new visual helpers, new profile
methods, or new examples with real external datasets. GitHub Actions and public
pkgdown deployment still need to run after push and PR.

## Next Actions

1. Push this branch and open a Phase 6b tutorial-quality PR.
2. Let GitHub Actions validate the docs branch.
3. Start Phase 6c only after deciding whether to merge Phase 6b first or stack
   random-slope implementation work on top.
