# After Task: Slice 139 emmeans zero-inflated NB2 boundary

## Goal

Add public-method evidence that zero-inflated NB2 fits still error before
`emmeans()` returns an `emmGrid`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a zero-inflated NB2 model and
checks that `emmeans()` errors before returning an `emmGrid`. The test requires
the error to name `"zi_nbinom2"` and to point users toward `prediction_grid()`
for explicit prediction tables.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes record this as
boundary coverage. The wording does not claim zero-inflated NB2 `emmeans`
support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-139-emmeans-zi-nbinom-boundary.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-224143-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a zero-inflated NB2 fit errored before returning an `emmGrid`,
  named `"zi_nbinom2"`, and suggested `prediction_grid()` plus
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
- Positive source/rendered scan for Slice 139 zero-inflated NB2 boundary
  wording and test evidence: found the expected entries.
- Stale-claim scan for zero-inflated NB2 `emmeans` support: no false support
  claims; matches were intentional unsupported-boundary wording or older
  zero-inflated NB2 model-support wording.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-224143-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #103 merged as `302b94a9bcb3f171b75413a6ca886a0e68be9f20`.
- `git rebase --onto origin/main f9b3b7bb5118bab5e16b5bcb6532dfb520f0d1c8`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test protects the same public unsupported boundary as the zero-inflated
Poisson sibling. Zero-inflated NB2 fitted response means combine `mu`, `sigma`,
and zero inflation, so they remain outside the first native univariate `mu`
`emmeans` bridge.

## Known Limitations

- Zero-inflated NB2 `emmeans` support remains unsupported.
- No fitted observed-response, hurdle, ordinal, non-`mu`, random-effect, or
  blocked-model workflow is added.

## Team Notes

Pat should keep zero-inflated examples pointed to `prediction_grid()` and
`predict_parameters()` until a later slice defines a tested `emmeans` estimand
for fitted observed-response means. Rose should keep scans separate between
zero-inflated NB2 model support and zero-inflated NB2 `emmeans` support.
