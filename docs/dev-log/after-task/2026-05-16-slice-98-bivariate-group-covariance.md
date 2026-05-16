# After Task: Slice 98 Bivariate Group-Level Covariance Polish

## Goal

Turn the bivariate tutorial's group-level covariance section from a conceptual
template into a compact runnable worked example. The example needed to start
from an individual-difference question, fit only implemented ordinary
bivariate Gaussian random-intercept syntax, and keep residual `rho12` distinct
from group-level covariance rows.

## Implemented

- Reworked the ending of `vignettes/bivariate-coscale.Rmd`.
- Added a repeated-individual activity-boldness simulation with 55 individuals
  and 7 repeated observations per individual.
- Fitted matching labelled random intercepts in the two location formulas:
  `mu1 = activity ~ food + disturbance + (1 | p | ID)` and
  `mu2 = boldness ~ food + (1 | p | ID)`.
- Kept `sigma1`, `sigma2`, and `rho12` constant in the grouped example so the
  tutorial's second lesson is the group-level `mu1`/`mu2` covariance row, not
  another residual-correlation curve.
- Added focused `check_drm(fit_group)` output for convergence,
  random-effect SD boundaries, residual-correlation boundaries, and the
  bivariate `mu` covariance diagnostic row.
- Added `corpairs(fit_group)` output showing the residual `rho12` row beside
  the group-level `mu1`/`mu2` row.
- Added `summary(fit_group)$covariance` output with component SDs,
  correlation, covariance, and scale labels on the report scale.
- Added `profile_targets(fit_group)` output for the two group-level SD targets
  and the group-level correlation target.
- Updated `ROADMAP.md`, `docs/design/21-tutorial-style.md`,
  `docs/design/37-worked-example-inventory.md`, `vignettes/drmTMB.Rmd`, and
  `vignettes/source-map.Rmd`.
- Recorded this slice in `docs/dev-log/check-log.md`.
- Wrote a recovery checkpoint before staging because this slice resumed from a
  crash-recovery context.

## Mathematical Contract

The grouped example fits an intercept-level location covariance block:

```text
mu1_ij = X_mu1[ij, ] beta_mu1 + b_0,1j
mu2_ij = X_mu2[ij, ] beta_mu2 + b_0,2j
(b_0,1j, b_0,2j)' ~ MVN(0, Sigma_mu_ID)
```

`Sigma_mu_ID` contains the among-individual SD in average activity, the
among-individual SD in average boldness, and their correlation. That
correlation is a group-level `corpairs(level = "group")` row. It is not
residual `rho12`, which remains the within-observation coupling in the
residual covariance matrix.

Because the tutorial mentions the all-four ordinary bivariate q=4
random-intercept block, it now names all six rows explicitly: one
`mu1`-`mu2` row, four mean-scale rows (`mu1`-`sigma1`, `mu1`-`sigma2`,
`mu2`-`sigma1`, and `mu2`-`sigma2`), and one `sigma1`-`sigma2` row.

## Files Changed

- `ROADMAP.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-114952-codex-checkpoint.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/source-map.Rmd`

## Checks Run

- `air format ROADMAP.md docs/design/21-tutorial-style.md docs/design/37-worked-example-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md vignettes/bivariate-coscale.Rmd vignettes/drmTMB.Rmd vignettes/source-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 98 bivariate group-level covariance polish" --next "git add the Slice 98 docs, commit, push, and open the PR"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-114952-codex-checkpoint.md`.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/bivariate-coscale.Rmd", output_dir = tempfile("biv-coscale-render-"), quiet = FALSE)'`:
  passed and rendered all new chunks with the source package loaded.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|corpairs", reporter = "summary")'`:
  passed; the bivariate Gaussian and `corpairs` test files completed with no
  failures.
- `Rscript -e 'pkgdown::build_site()'`: passed and rendered the updated
  bivariate article, Getting Started article, source map, roadmap, and site
  index.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- Source and rendered scans confirmed the individual-difference section,
  `fit_group`, `corpairs(fit_group)`, `summary(fit_group)$covariance`, the
  bivariate `mu` covariance diagnostic, the Slice 98 inventory entry, and the
  all-four q=4 pair wording.
- Boundary scans confirmed that bivariate random slopes,
  plasticity-syndrome slope correlations, `rho12` random effects, bivariate
  known-`V` plus random effects, mixed-response models, and ordinary spatial
  group-level covariance remain planned.
- Added-line non-ASCII scan with `git diff --unified=0` and `perl` returned
  no matches.

## Tests Of The Tests

No new tests were added because the slice changed tutorial and status prose
only. Curie treated the existing `test-biv-gaussian.R` and `test-corpairs.R`
coverage as the implementation guardrail. Those tests already fit the
`mu1`/`mu2` random-intercept covariance block, check `corpairs()` filters and
rows, check the same-response and sigma covariance paths, and exercise the
ordinary q=4 all-four intercept block.

The tutorial itself is also executable evidence: the source-loaded render and
`pkgdown::build_site()` both fitted the grouped model and printed the
diagnostic, `corpairs()`, covariance, and profile-target tables.

## Consistency Audit

Ada kept the slice documentation-only. No formula grammar, family registry,
likelihood parameterization, TMB code, extractor code, or test implementation
changed.

Rose checked for stale status around q=4 covariance and found an older roadmap
sentence that still described the all-four ordinary bivariate random-intercept
block as hidden. The roadmap now says the ordinary q=4 intercept block is
fitted, while q=3 scaffolds, q > 4 blocks, q=6/q=8 random-slope endpoint
blocks, bivariate random slopes, and the full double-hierarchical endpoint
remain future work.

Pat's reader route is now clearer: the article first teaches residual
`rho12`, then teaches a separate repeated-individual covariance question. The
Getting Started learning path now points repeated-individual questions to the
same article rather than only to the model map.

## What Did Not Go Smoothly

A standalone `rmarkdown::render("vignettes/bivariate-coscale.Rmd")` first
failed because it loaded an older installed `drmTMB` instead of the source
tree. That installed version rejected bivariate random effects. Rerunning the
render after `pkgload::load_all(".", quiet = TRUE)` passed, and
`pkgdown::build_site()` also passed because it installs and renders the current
source package.

The first status scan also exposed the stale q=4 roadmap wording noted above.
Fixing it was inside the Slice 98 consistency boundary because the tutorial
now mentions the all-four row set.

## Team Learning

Ada should treat source-loaded rendering as the right local smoke test for
vignettes that depend on current uninstalled features. Rose should scan
roadmap status whenever a tutorial boundary mentions q=4 or structured
covariance, because older hidden-probe language can become stale as fitted
support lands. Noether should keep forcing q=4 prose to list all four
mean-scale pairs instead of using a compressed "mean-scale rows" phrase alone.

## Known Limitations

Slice 98 does not add new model support. The new fitted example is ordinary
bivariate Gaussian random-intercept covariance only. It does not teach
bivariate random slopes, slope1-slope2 plasticity-syndrome correlations,
random effects in `rho12`, bivariate `meta_known_V()` plus random effects,
mixed-response families, ordinary spatial group-level covariance, or the full
double-hierarchical endpoint as fitted syntax.

The grouped tutorial prints focused `check_drm()` rows rather than the full
diagnostic table so the reader can see the covariance check clearly. In a real
analysis, the full `check_drm(fit_group)` output should still be inspected.

## Next Actions

1. Open the Slice 98 PR and let GitHub Actions run.
2. If CI passes, merge the documentation-only slice.
3. Leave large-data benchmarking parked until Phase 14 produces
   benchmark-backed evidence.
