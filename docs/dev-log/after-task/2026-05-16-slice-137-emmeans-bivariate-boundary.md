# After Task: Slice 137 emmeans bivariate public boundary

## Goal

Make the public `emmeans()` boundary for bivariate Gaussian fits name the
unsupported `"biv_gaussian"` model type before `emmeans()` returns an `emmGrid`.

## Implemented

`R/emmeans-preflight.R` now checks the supported model type before checking for
a fitted `mu` coefficient. That ordering lets bivariate Gaussian fits fail with
the explicit unsupported `"biv_gaussian"` message instead of the generic
missing-`mu` message.

`tests/testthat/test-emmeans-methods.R` now fits a small `biv_gaussian()` model
and checks that `emmeans()` errors before returning an `emmGrid`. The test
requires the error to name `"biv_gaussian"` and to point users toward
`prediction_grid()` for explicit prediction tables.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes record this as
boundary coverage. The wording does not claim bivariate `emmeans` support.

## Files Changed

- `NEWS.md`
- `R/emmeans-preflight.R`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-137-emmeans-bivariate-boundary.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-222509-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a bivariate Gaussian fit previously errored with the generic
  missing-`mu` message, even though the model type was unsupported.
- `air format R/emmeans-preflight.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 137 bivariate boundary wording and
  test evidence: found the expected entries.
- Stale-claim scan for bivariate `emmeans` support: no false support claims;
  the only match was intentional unsupported-boundary wording.
- Upstream Slice 132 PR #97 merged with squash commit
  `69e4383a6ff3487846193229cfaa8035f298beb7`.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-222509-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #101 merged as `8f4fa9d71f1df20691a1a1abb7b8b42c2ad7e289`.
- `git rebase --onto origin/main c5a54bfe7b310925b259422d98b3477aeb831754`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The change improves error specificity without extending the estimand. Bivariate
models expose `mu1` and `mu2`, while the first `emmeans` bridge is limited to a
native univariate fixed-effect `mu` target. Users who need bivariate prediction
tables should still use `prediction_grid()` and `predict_parameters()`.

## Known Limitations

- Bivariate Gaussian `emmeans` support remains unsupported.
- No fitted observed-response, non-`mu`, zero-inflated, hurdle, ordinal,
  random-effect, or blocked-model workflow is added.

## Team Notes

Ada should rebase Slice 133 through Slice 137 onto the new `origin/main` after
this slice is committed. Rose should keep checking that unsupported-boundary
wording does not drift into a claim of bivariate `emmeans` support.
