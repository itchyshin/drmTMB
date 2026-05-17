# After Task: Slice 142 emmeans ordered-factor grid

## Goal

Preserve ordered-factor predictor coding when fixed-effect prediction `newdata`
or an `emmeans()` reference grid supplies fitted ordered-factor levels as an
ordinary factor.

## Implemented

`R/methods.R` now prepares fixed-effect prediction `newdata` by reusing fitted
factor levels and ordered status before model-matrix construction. This keeps
ordered predictor columns such as `condition.L` and `condition.Q` aligned with
the fitted coefficient vector when a reference grid supplies `condition` as a
plain factor.

`tests/testthat/test-fixed-effect-basis.R` covers the low-level basis path.
`tests/testthat/test-emmeans-methods.R` covers the public bridge with
`emmeans(fit, ~ condition | habitat, at = list(x = 0.2))`, checking that the
returned EMMs match `predict(dpar = "mu")` on the same ordered-factor grid.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes record this as
ordered-factor predictor coding preservation. The wording does not claim
ordinal-response `emmeans()` support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-142-emmeans-ordered-factor-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-001450-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`
- `tests/testthat/test-fixed-effect-basis.R`

## Checks Run

- No-edit scout:
  the ordered-factor `emmeans()` grid failed before the fix with
  `Could not align the "mu" design matrix with fitted coefficients`.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/40-emmeans-interface-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-142-emmeans-ordered-factor-grid.md tests/testthat/test-emmeans-methods.R tests/testthat/test-fixed-effect-basis.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 142 ordered-factor wording and test
  evidence: found the expected entries.
- Stale-claim scan for accidental ordinal-response `emmeans` support claims:
  no matches.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-001450-codex-checkpoint.md`.

## Consistency Audit

This patch changes how fixed-effect prediction matrices prepare factor-valued
`newdata`; it does not change likelihoods, formula grammar, or the definition
of an EMM. The public `emmeans()` bridge remains limited to fixed-effect
univariate `mu` targets with retained model frames and fixed-effect covariance.

Ordered-factor predictors are separate from ordinal responses. Cumulative-logit
ordinal-response fits still error before returning an `emmGrid`.

## Known Limitations

- The fix depends on fitted data or retained model frames being available as a
  template for factor levels and ordered status.
- No ordinal-response `emmeans()` support, non-`mu` target, transformed
  response, empirical marginalisation, random-effect workflow, or blocked model
  structure is added.

## Team Notes

Pat should keep examples explicit when "ordered" means an ordered predictor
rather than an ordinal response. Rose should keep stale-claim scans watching
for wording that accidentally converts this coding fix into an ordinal
`emmeans()` support claim.
