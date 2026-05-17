# After Task: Slice 135 emmeans hurdle public boundary

## Goal

Add public-method evidence that hurdle NB2 fits still error before `emmeans()`
returns an `emmGrid`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a hurdle NB2 model and checks
that `emmeans()` errors before returning an `emmGrid`. The test requires the
error to name `"hurdle_nbinom2"` and to point users toward `prediction_grid()`
for explicit prediction tables.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now record this as
boundary coverage. The wording does not claim hurdle `emmeans` support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-135-emmeans-hurdle-public-error.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-220916-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a hurdle NB2 fit errored before returning an `emmGrid`, named
  `"hurdle_nbinom2"`, and suggested `prediction_grid()` plus
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
- Positive source/rendered scan for Slice 135 hurdle boundary wording and test
  evidence: found the expected entries.
- Stale-claim scan for hurdle `emmeans` support: no false support claims;
  matches were intentional unsupported-boundary wording.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-220916-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #99 merged as `4a10206ce2444b77dcd40e71fc20019b2b25c01b`.
- `git rebase --onto origin/main 24b2609efab21909f6e33cddb868c115add53268`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The test protects the public unsupported boundary already enforced by the
internal preflight helper. It keeps hurdle observed-response means out of the
first `emmeans` bridge because those fitted means combine the count component,
zero truncation, and hurdle probability.

## Known Limitations

- Hurdle `emmeans` support remains unsupported.
- No zero-inflated, ordinal expected-score, fitted observed-response, non-`mu`,
  random-effect, or blocked-model workflow is added.

## Team Notes

Pat should keep hurdle prediction guidance pointed to `prediction_grid()` and
`predict_parameters()` until a later slice defines a tested `emmeans` estimand
for hurdle models.
