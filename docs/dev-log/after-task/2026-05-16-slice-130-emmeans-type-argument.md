# After Task: Slice 130 emmeans direct type argument coverage

## Goal

Add explicit evidence for the path where users ask for response-scale estimated
marginal means by passing `type = "response"` directly to
`emmeans::emmeans()`, rather than first building an EMM grid and then calling
`summary(..., type = "response")`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Poisson fixed-effect `mu`
model and checks both direct type paths on the same reference grid:
`emmeans(..., type = "link")` must match
`predict(dpar = "mu", type = "link")`, and
`emmeans(..., type = "response")` must match
`predict(dpar = "mu", type = "response")`.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now state the
reader-facing contract: response-scale EMMs are inverse-link summaries of native
distributional parameter `mu`. They are not fitted observed-response summaries
for blocked model structures.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-130-emmeans-type-argument.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-213838-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 130 direct `type` argument wording and
  tests: found the expected entries.
- Stale-claim scan for `type = "response"` as unsupported or response-scale
  EMMs as unsupported: no Slice 130 contradictions; the only match was the
  earlier Slice 125 boundary that the covered gate was not widened.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-213838-codex-checkpoint.md`.

Post-rebase checks:

- PR #94 merged as `b4d2857065368e76fadc16b14b768fe912fae225`.
- `git rebase --onto origin/main b4aba3562fa0381aaa4b0f2863b134226d4c1736`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test confirms that direct `type` routing through `emmeans()` reaches the
same link and inverse-link scales already exposed through `predict(dpar =
"mu")`. The docs keep this tied to native `mu`; they do not imply that
`emmeans` now supports blocked-model fitted means, non-`mu` targets, or custom
observed-data averaging.

## Known Limitations

- Only fixed-effect univariate `mu` models are covered.
- No non-`mu`, random-effect, blocked, transformed-response, slope,
  custom-weight, or empirical-marginalisation workflow is added.
- This is a contract and regression-test slice; it does not change likelihoods,
  formula grammar, or S3 object structure.

## Team Notes

Boole should keep `type`, `at`, `cov.reduce`, custom weights, and empirical
grids named separately in future docs. Pat should describe response scale as a
distributional-parameter scale unless a later slice adds and tests a different
fitted-response estimand.
