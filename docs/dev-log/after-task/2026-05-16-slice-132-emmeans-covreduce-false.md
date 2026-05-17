# After Task: Slice 132 emmeans unreduced covariate grid

## Goal

Add explicit evidence that the first fixed-effect univariate `mu`
`emmeans()` bridge respects `cov.reduce = FALSE`, where `emmeans` keeps the
numeric covariate levels in the reference grid rather than reducing them to one
value.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect `mu`
model with three observed `x` levels and checks that
`emmeans(..., cov.reduce = FALSE)` matches `predict(dpar = "mu")` averaged over
those same `x` levels in the `emmeans` reference grid.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now state this as
grid averaging by `emmeans`. The wording keeps it separate from drmTMB
row-wise empirical marginalisation.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-132-emmeans-covreduce-false.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-215050-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans(..., cov.reduce = FALSE)` matched the mean of
  `predict(dpar = "mu")` over the unreduced observed `x` levels.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 132 `cov.reduce = FALSE` wording and
  tests: found the expected entries.
- Stale-claim scan for `cov.reduce = FALSE` as unsupported, row-wise empirical
  averaging as implemented, or custom weights as implemented: no matches.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-215050-codex-checkpoint.md`.

Post-rebase checks:

- PR #96 merged as `e468ba44cae3623c3bbc7c7e0e81e39c8c60920d`.
- `git rebase --onto origin/main e8b3b0e6649c7890d244119d63897c705b23ee07`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test checks `emmeans` grid averaging over unreduced numeric covariate
levels. It does not claim support for row-wise empirical averaging over the
original data, for custom weights, or for non-`mu` targets; those remain
separate estimands and should use separate contracts if added later.

## Known Limitations

- Only fixed-effect univariate `mu` models are covered.
- No custom-weight, row-wise empirical-marginalisation, slope, non-`mu`,
  transformed-response, random-effect, or blocked-model workflow is added.

## Team Notes

Pat and Fisher should keep future examples explicit about whether an average is
over `emmeans` grid levels, original rows, or a user-supplied empirical grid.
