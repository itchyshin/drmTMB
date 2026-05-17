# After Task: Slice 138 emmeans transformed-response boundary

## Goal

Block transformed-response formulas from the first public `emmeans()` bridge
before `emmeans()` returns an `emmGrid`.

## Implemented

`R/emmeans-preflight.R` now checks for transformed responses during the first
`mu` `emmeans` target validation. Ordinary response names and `cbind()`
beta-binomial responses remain allowed, while response formulas such as
`log(y) ~ x` are rejected with guidance toward explicit transformed-scale
prediction tables.

`tests/testthat/test-emmeans-preflight.R` now covers the private guard, and
`tests/testthat/test-emmeans-methods.R` now covers the public `emmeans()` path.
Both tests require transformed-response fits to error before an `emmGrid` is
returned.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes record this as
boundary coverage. The wording keeps transformed responses separate from the
transformed-predictor path added in Slice 128.

## Files Changed

- `NEWS.md`
- `R/emmeans-preflight.R`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-138-emmeans-transformed-response-boundary.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-223354-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`
- `tests/testthat/test-emmeans-preflight.R`

## Checks Run

- No-edit scout:
  `emmeans()` on `bf(log(y) ~ x + habitat, sigma ~ 1)` previously returned an
  `emmGrid`, despite the interface contract excluding transformed responses.
- `air format R/emmeans-preflight.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-preflight.R tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-preflight|emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 138 transformed-response boundary
  wording and tests: found the expected entries.
- Stale-claim scan for transformed-response `emmeans` support: no false support
  claims; the only match was the intentional Slice 128 note that transformed
  predictors are not transformed-response support.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-223354-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #102 merged as `d3096082d60a73a6824f81660dc9badfcb059832`.
- `git rebase --onto origin/main 65bc30e8d777e7b9c84501333aee2b2d5518334f`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The first `emmeans` bridge estimates EMMs for a native univariate fixed-effect
`mu` parameter over an `emmeans` reference grid. A transformed response such as
`log(y)` changes the response scale and needs an explicit interpretation and
delta-method contract before it can be advertised through `emmeans`. Users can
still build explicit transformed-scale prediction tables with
`prediction_grid()` and `predict_parameters()`.

## Known Limitations

- Transformed-response `emmeans` support remains unsupported.
- No delta-method transformed-response, fitted observed-response, non-`mu`,
  zero-inflated, hurdle, ordinal, random-effect, or blocked-model workflow is
  added.

## Team Notes

Pat should keep examples clear about the difference between transformed
predictors, which are covered, and transformed responses, which remain outside
the first public `emmeans` bridge. Rose should continue stale-claim scans for
that distinction.
