# After Task: Slice 131 emmeans custom covariate reduction

## Goal

Add explicit evidence that the first fixed-effect univariate `mu`
`emmeans()` bridge respects a custom numeric covariate-reduction function. The
concrete path is `emmeans(..., cov.reduce = stats::median)` for a model with a
skewed numeric covariate.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect `mu`
model with a deliberately skewed `x` distribution and checks that
`emmeans(..., cov.reduce = stats::median)` matches
`predict(dpar = "mu")` at `median(x)`.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now state this as
ordinary `emmeans` reference-grid behaviour. The text keeps custom covariate
reduction separate from drmTMB-specific empirical averaging and custom weights.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-131-emmeans-covreduce-median.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-214431-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans(..., cov.reduce = stats::median)` shifted the grid away from the
  default mean as expected in a skewed fixed-effect Gaussian `mu` example.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 131 `cov.reduce = stats::median`
  wording and tests: found the expected entries.
- Stale-claim scan for `cov.reduce` as unsupported or custom weighting as
  implemented: no contradictions; matches were the intentional boundary
  sentences saying this is not drmTMB-specific empirical averaging or custom
  weighting.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-214431-codex-checkpoint.md`.

Post-rebase checks:

- PR #95 merged as `a0425dbb417578fe5374d3d1e254f70397a1c0cf`.
- `git rebase --onto origin/main c06f83cea77eff218d890b037869c7ed24913275`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test confirms that `cov.reduce` changes the numeric reference grid passed
through `emmeans`. It does not make `emmeans()` an empirical averaging engine:
row-wise observed-data averaging remains a separate `marginal_parameters()`
contract unless a later slice adds and tests a different workflow.

## Known Limitations

- Only fixed-effect univariate `mu` models are covered.
- No custom-weight, empirical-marginalisation, slope, non-`mu`,
  transformed-response, random-effect, or blocked-model workflow is added.

## Team Notes

Boole and Pat should continue to say which grid point an adjusted mean uses:
explicit `at`, default numeric mean reduction, custom `cov.reduce`, or
empirical row averaging are different estimands and should not be blurred.
