# After Task: Slice 134 emmeans zero-inflated public boundary

## Goal

Add public-method evidence that zero-inflated Poisson fits still error before
`emmeans()` returns an `emmGrid`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a zero-inflated Poisson model
and checks that `emmeans()` errors before returning an `emmGrid`. The test
requires the error to name `"zi_poisson"` and to point users toward
`prediction_grid()` for explicit prediction tables.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now record this as
boundary coverage. The wording does not claim zero-inflated `emmeans` support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-134-emmeans-zi-public-error.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-220410-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a zero-inflated Poisson fit errored before returning an
  `emmGrid`, named `"zi_poisson"`, and suggested `prediction_grid()` plus
  `predict_parameters()`.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 134 zero-inflated boundary wording
  and test evidence: found the expected entries.
- Stale-claim scan for zero-inflated `emmeans` support: no false support
  claims; matches were intentional unsupported-boundary wording.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-220410-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #98 merged as `63855fc008ae7d0c1c342aea4affd40faa9e36cc`.
- `git rebase --onto origin/main 3d476a2659a9cc37da143244ac88107d44bcdf33`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test protects the public unsupported boundary already enforced by the
internal preflight helper. It keeps zero-inflated response means out of the
first `emmeans` bridge because those fitted means combine `mu` and the
zero-inflation parameter.

## Known Limitations

- Zero-inflated `emmeans` support remains unsupported.
- No hurdle, ordinal expected-score, fitted observed-response, non-`mu`,
  random-effect, or blocked-model workflow is added.

## Team Notes

Pat should keep user guidance pointed to `prediction_grid()` and
`predict_parameters()` for zero-inflated prediction tables until a later slice
defines a tested `emmeans` estimand for those models.
