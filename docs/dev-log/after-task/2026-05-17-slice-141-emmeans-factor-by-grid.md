# After Task: Slice 141 emmeans factor-conditioned grid

## Goal

Add positive coverage that factor-conditioned `emmeans()` reference grids
preserve factor levels and match fixed-effect `mu` predictions.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect model
with `habitat`, `season`, and a numeric covariate, then checks
`emmeans(fit, ~ habitat | season, at = list(x = 0.25))` against
`predict(dpar = "mu")` on the same factor-conditioned grid.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes record this as
ordinary factor-conditioned reference-grid coverage. The wording does not claim
empirical row-weighted marginalisation.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-141-emmeans-factor-by-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-000427-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a Gaussian `habitat` by `season` grid at `x = 0.25` matched
  `predict(dpar = "mu")` exactly.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 141 factor-conditioned grid wording
  and test evidence: found the expected entries.
- Stale-claim scan for empirical row-weighted marginalisation from factor-grid
  wording: no false support claims; the only match was the intentional design
  note that this is not empirical row-weighted marginalisation.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-000427-codex-checkpoint.md`.

## Consistency Audit

The test checks ordinary `emmeans` conditioning on a factor variable while
holding the numeric covariate at an explicit value. It protects factor-level
recovery and grid construction without expanding the bridge to empirical
row-weighted margins.

## Known Limitations

- This slice covers ordinary factor conditioning for fixed-effect univariate
  `mu` only.
- No non-`mu`, transformed-response, empirical-marginalisation, random-effect,
  or blocked-model workflow is added.

## Team Notes

Pat should keep examples explicit about whether factor levels are conditioned
or averaged. Rose should keep stale-claim scans watching for accidental
empirical-marginalisation language around factor-conditioned EMMs.
