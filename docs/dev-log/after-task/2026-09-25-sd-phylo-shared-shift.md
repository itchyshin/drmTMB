# After-task: shared-shift optimum for covariate-dependent phylogenetic SD

## Goal

Document and diagnose a second optimum found in a collaborator's whole-tree bird
analysis for models with `sd(species, level = "phylogenetic") ~ covariates`
(legacy `sd_phylo(species) ~ covariates`), without changing the likelihood or its
parameterisation. Deliverables: a design note, a `check_drm()` row with tests, and
this report.

## What changed

- `docs/design/277-sd-phylo-root-offset-identifiability.md` (new): mechanism,
  evidence, conditions, user advice, the diagnostic, and the open
  parameterisation decision.
- `R/check.R`: new internal `phylo_shared_shift_statistic()`,
  `check_phylo_sd_shared_shift()`, and `phylo_shared_shift_message()`, registered
  in `check_drm.drmTMB()` after `check_phylo_direct_sd_model()`; one added
  paragraph in the `check_drm()` roxygen details.
- `man/check_drm.Rd`: regenerated; the diff is that paragraph only.
- `tests/testthat/test-check-phylo-sd-shared-shift.R` (new): 6 tests, 24
  expectations, 5 `skip_if_not_installed("ape")` sites (`ape` is in Suggests).
- `inst/extdata/env-skip-census.tsv`: one new row for that file, regenerated
  with `Rscript tools/write-env-skip-census.R`; no other row moved.
- `docs/dev-log/check-log.d/2026-09-25-sd-phylo-shared-shift.md` (new) and this
  report.

Lane: branch `claude/sd-phylo-root-offset-20260925` in its own worktree off
`origin/main` `b737b3bad`. The live arc1 lane leases `tests/testthat/`,
`docs/dev-log/after-task/`, `docs/dev-log/check-log.d/`, `inst/extdata/` and
`tools/`; Shinichi approved adding the new files there on 2026-09-25. The census
row is the one edit to an existing file under that lease, required for the
census guard to pass. No arc1 file was changed.

The new row, `phylo_sd_shared_shift`, reports
\(z_{\text{shared}} = \mathbf{1}^\top Q \hat u / \sqrt{\mathbf{1}^\top Q \mathbf{1}}\)
from the stored conditional modes and precision, so it needs no refit and works
without the TMB object. Status is `ok` below 2, `note` from 2, `warning` from 3.
Intercept-only SD models and models without a direct-SD formula get no row.
Bivariate `sd1()`/`sd2()` phylogenetic models get one row per endpoint.

## Checks run

- New tests with the census guard, `devtools::test(filter =
  "check-phylo-sd-shared-shift|env-skip-census")`: 24 + 5 expectations,
  0 failures, 0 errors.
- Existing tests via `devtools::test(filter = ...)`:
  `test-check-drm.R` 283, `test-check-conditioning.R` 37 (1 existing skip),
  `test-gaussian-random-effect-scale.R` 89, `test-reml-direct-sd-phylo.R` 8,
  `test-beta-phylo-direct-sd.R` 44; 461 expectations, 0 failures, 0 errors.
- A wider filter over the files that call `check_drm()` on direct-SD
  phylogenetic fits (`animal-relmat-gaussian`, `beta-location-scale`,
  `biv-gaussian`, `control`, `count-structured-mu`,
  `estimator-surface-conformance`, `gradient-conformance`, `mesh-contract`,
  `nbinom2-location-scale`, `phylo-gaussian`) matched 27 test files, including
  the phase-18 bivariate suites and `test-phylo-gaussian.R` (404 expectations):
  3,711 expectations, 0 failures, 0 errors.
- Real-data end-to-end run (collaborator data, tree position 1, not committed):
  default fit `ok` (z = 0.47), fit seeded at the shifted optimum `warning`
  (z = 3.74, log-likelihood -29343.08, matching the shifted solution), quadratic
  mean `ok` (z = -0.10), constant phylogenetic SD no row.
- `devtools::document()` rewrote about 40 unrelated `.Rd` files (local roxygen
  output differs from the committed pages); those were reverted and only
  `man/check_drm.Rd` kept.
- Not run: full `devtools::check()`, `pkgdown::check_pkgdown()`.

## Tests of the tests

Two deliberate mutants, run against the new test file:

- replacing the precision-weighted statistic with an unweighted sum of the latent
  values: 7 of 24 expectations fail;
- making `check_phylo_sd_shared_shift()` return `NULL`: 13 of 24 fail.

The threshold tests move the stored conditional modes by a computed shared shift
to hit z = 0.5, 2.5 and -3.5 exactly, so the `ok`/`note`/`warning` boundaries are
tested directly rather than depending on whether a small simulation happens to
land in a second optimum. The bivariate test shifts only the `mu2` block and
checks that only the `mu2` row changes, which pins the stacked latent layout.

## Consistency audit

- Code and note agree on the statistic, the thresholds (2, 3), the row name, and
  the skip rule for intercept-only SD models.
- The roxygen paragraph uses the current `sd(..., level = "phylogenetic")`
  spelling and names the row.
- The stored `random_effects$phylo_mu$latent` was checked to equal the raw
  `u_phylo` vector exactly in a bivariate fit (max difference 0), and its blocks
  are ordered `mu1` then `mu2`, matching `effect_index = k * n_phylo + node` in
  `src/drmTMB.cpp`.
- The evidence numbers in the note were re-derived after review: the
  precipitation shift-ratio correlation is 0.89 once the third solution type is
  kept separate (an earlier 0.997 merged it into solution B).

## What did not go smoothly

- The first statement of the mechanism called the two solutions equivalent fits
  of one pattern. Review corrected this: solution B pays a prior cost for a better
  fit to the curvature, so the surface has separate optima, not a ridge.
- "Cheap on deep trees" was the wrong reason; the prior cost is
  \(\tfrac12\delta^2\,\mathbf{1}^\top Q\mathbf{1}\), set by the edges leaving the
  root after height scaling.
- `devtools::document()` produced unrelated `.Rd` churn that had to be reverted.

## Team learning

A multistart diagnostic is most informative with a start aimed at the suspected
direction, not a random jitter. Seeding only the location coefficients along
\(-c\,e^{\alpha_0}(1, \alpha_T, \alpha_P)\) reached the shifted optimum exactly;
whether `drm_control(multi_start = )` finds it was not tested.

## Design-doc updates

New note 277. Note 35's "Future Multi-Start Contract" predates the public
`drm_control(multi_start = , start = )` arguments and is now stale; not edited
here (outside this lane's claim), flagged for its owner.

## pkgdown/documentation updates

`check_drm()` help gains one paragraph. No vignette, `_pkgdown.yml`, or NEWS
change in this slice; `NEWS.md` is under another lane's lease and should get a
one-line entry at merge.

## GitHub issue maintenance

No drmTMB issue exists for this. The trigger is a collaborator's private
repository issue; the collaborator has been told a `check_drm()` row is coming.

## Known limitations and next actions

- Thresholds are calibrated on one data set (two trees, four fits).
- The diagnostic reads conditional modes; it detects the shifted solution, not
  the existence of a second optimum when the fit sits in solution A.
- Other per-observation-scaled latent fields (future spatial, animal, `relmat()`
  direct-SD routes) need the same check when implemented.
- Open decision for Shinichi: whether to change the parameterisation (centre the
  latent field, or estimate a separate root value). Not implemented.
