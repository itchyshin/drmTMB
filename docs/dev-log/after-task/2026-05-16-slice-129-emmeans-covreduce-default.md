# After Task: Slice 129 emmeans default covariate reduction

## Goal

Add explicit evidence for the default numeric covariate-reduction rule in the
first fixed-effect univariate `mu` `emmeans()` bridge. The concrete reader path
is `emmeans(fit, ~ habitat)` when the fitted model also contains a numeric
covariate `x`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect `mu`
model with an asymmetric numeric covariate and checks that
`emmeans(fit, ~ habitat)` matches `predict(dpar = "mu")` at `mean(x)`.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now state that this
is ordinary `emmeans` reference-grid behaviour. The docs keep empirical
marginalisation and custom weighting separate from this default mean-reference
grid.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-129-emmeans-covreduce-default.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-213102-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 129 covariate-reduction wording and
  tests: found the expected entries.
- Stale-claim scan for covariate reduction as unsupported or for custom
  weighting as implemented: no matches.
- `git diff --check`: passed.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-213102-codex-checkpoint.md`.

Post-rebase checks:

- PR #93 merged as `ac97052adace5510cdaab72c56b839a2c804cb40`.
- `git rebase --onto origin/main 1ddc819b9cc3cfde1983e6ff3cd5af9ce3c747fb`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The new test covers the default `emmeans` behaviour for numeric covariates. It
does not turn this into a drmTMB-specific empirical marginalisation rule; users
should still use `marginal_parameters()` for empirical averaging over fitted
rows or supplied `newdata` groups.

## Known Limitations

- Only the default numeric mean reduction is tested.
- No custom-weight, empirical-marginalisation, slope, non-`mu`, transformed
  response, or blocked-model workflow is added.

## Team Notes

Boole should keep `at`, default covariate reduction, empirical grids, and custom
weights named separately in future docs. Pat should keep examples explicit about
which grid a reported EMM represents.
