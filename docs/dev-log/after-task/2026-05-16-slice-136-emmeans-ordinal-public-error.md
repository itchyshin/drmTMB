# After Task: Slice 136 emmeans ordinal public boundary

## Goal

Add public-method evidence that cumulative-logit ordinal fits still error before
`emmeans()` returns an `emmGrid`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a cumulative-logit ordinal
model and checks that `emmeans()` errors before returning an `emmGrid`. The test
requires the error to name `"cumulative_logit"` and to point users toward
`prediction_grid()` for explicit prediction tables.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now record this as
boundary coverage. The wording does not claim ordinal expected-score `emmeans`
support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-136-emmeans-ordinal-public-error.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-221705-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a cumulative-logit fit errored before returning an `emmGrid`,
  named `"cumulative_logit"`, and suggested `prediction_grid()` plus
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
- Positive source/rendered scan for Slice 136 ordinal boundary wording and test
  evidence: found the expected entries.
- Stale-claim scan for ordinal `emmeans` support: no false support claims;
  matches were intentional unsupported-boundary wording.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-221705-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #100 merged as `5024d1350a3843c58819862c114be4a909b61c01`.
- `git rebase --onto origin/main e694e7f0a1a38f8d5a0884686d338d1941268ce2`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test protects the public unsupported boundary already enforced by the
internal preflight helper. It keeps ordinal expected-score EMMs out of the first
`emmeans` bridge because those summaries are not native fixed-effect `mu`
location EMMs.

## Known Limitations

- Ordinal expected-score `emmeans` support remains unsupported.
- No zero-inflated, hurdle, fitted observed-response, non-`mu`, random-effect,
  or blocked-model workflow is added.

## Team Notes

Pat should keep ordinal prediction guidance pointed to `prediction_grid()` and
`predict_parameters()` until a later slice defines a tested `emmeans` estimand
for ordinal expected scores.
