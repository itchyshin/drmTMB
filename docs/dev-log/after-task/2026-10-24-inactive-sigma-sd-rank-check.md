# After Task: Ignore Inactive Random-Effect SD Designs in Rank Checks

## 1. Goal

Prevent an unused `sd_sigma` design matrix from being reported as a rank-
deficient fixed effect when no random effect is fitted for `sigma`.

## 2. Implemented

Both fixed-effect rank diagnostics now omit `sd_mu` or `sd_sigma` only when the
matching random-scale descriptor reports zero fitted models. Active SD designs
remain part of the rank check. The regression fixture uses the real
beta-binomial model-spec builder, where `sd_sigma` is stored as a zero-column-
information matrix even though the sigma random-effect count is zero.
Both diagnostics use the shared internal `drm_twin_rank_tol` constant,
preserving the `1e-8` rank threshold.

## 3a. Decisions and Rejected Alternatives

No likelihood or model parameterization changed. Rank diagnostics inspect
estimated fixed-effect designs; an SD design with no corresponding latent
random effect is inactive and is not an estimable design matrix.

I retained the active-design rank check. Omitting every `sd_*` column would
hide genuine rank deficiencies, so the filter is tied to each endpoint's
`n_models` count.

## 4. Files Touched

- `R/check.R`: filter inactive random-scale design matrices for both rank
  diagnostics.
- `tests/testthat/test-check-fixed-effect-rank.R`: cover inactive sigma and
  continued detection of an active rank-deficient sigma SD design.
- This report and its check-log entry.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "check-fixed-effect-rank", reporter = "summary", stop_on_failure = TRUE)'`: passed, six expectations, zero failures, warnings, or skips.
- `git diff --check -- R/check.R tests/testthat/test-check-fixed-effect-rank.R R/julia-bridge.R tests/testthat/test-julia-binomial-animal-iid-sd-parity.R`: passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-24-inactive-sigma-sd-rank-check.md`: structure passed; the checker found 13 acceptance-ledger files but could not run the ledger because its node or gate-check was missing. Gate state is unknown.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <absolute report path>`: zero findings.
- Current candidate SHA-256: `R/check.R` `0c4acbf8c48c5f03b8d869140dd428d4d56670a24097b7610b4558eeae12e1cf`; test `c1f2456deeccaa5483749e7d1d13dbb4be779b14f51d48cacdb6ee1557f7b7ac`.
- The separate live Binomial animal-plus-IID bridge test passed once with the paired Julia candidate and Julia 1.10.0. It exercised the A and Ainv fits. That result is recorded here as adjacent goal evidence, not as a rank-check test.

## 6. Tests of the Tests

The initial regression test failed before the fix: the inactive `sd_sigma`
matrix was included and triggered all three expected rank-check failures. The
final fixture was then strengthened to use `drm_build_beta_binomial_spec()`.
The active-design case confirms the filter does not hide a real rank defect.

## 7a. Issue Ledger

GitHub search query: `repo:itchyshin/drmTMB is:issue "rank deficiency" OR sd_sigma`.
It found the open #1470 about rank-deficient scale designs.
That issue concerns aliased active predictors and missing alias handling; this
change concerns a false positive from an inactive SD endpoint. No issue was
changed and no duplicate was opened.

## 8. Consistency Audit

Search run: `rg -n "rank deficiency|rank-deficient|sd_sigma|random-effect scale|predictor-dependent" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.
The model grammar and public feature status are unchanged, so no user-facing
status inventory or navigation edit was needed. The implementation and both
rank-check call sites use the same filtered design list.

## 9. What Did Not Go Smoothly

The shared lane registry scan took over ten minutes to inspect hundreds of
lease records. The new report paths were absent from disk and every ref before
creation. The scoped lease expansion eventually completed and now covers the
code, regression test, report, and check log.

## 10. Known Residuals

This check does not repair inference for aliased active designs such as those
tracked in #1470. It does not change fitting, add a new SD capability, or
establish interval coverage. The package-wide goal remains open.

## 11. Team Learning

Memory receipt: the route script returned no LOAD-FIRST manifest for this
worktree. I used the completed read-only diff review and the repository's
after-task protocol; no additional routed memory was available. Golden Set:
not in scope for this diagnostic regression.

Model-spec tests should distinguish inactive endpoint bookkeeping from active
estimated designs. Reuse a real family builder for that boundary, then retain a
separate active-design negative case.

## 12. Cross-Product Coverage

The regression exercises R-side diagnostics with a beta-binomial model spec.
It does NOT cover Julia parity, response-family breadth, or
calibrated uncertainty. Coverage calibration remains deferred under the
approved project plan.

## Prose Assessment

Style: 2/10, medium confidence. Genre/coverage: technical after-task report,
whole draft reviewed. Evidence/repair: the phrase "This is an R-side diagnostic
regression" was indirect; it now states directly that the regression exercises
the R diagnostics. No further edit was needed. Gates: science = pass for this
diagnostic-only claim; facts = pass against the focused test output and source;
references = not applicable because no external sources are cited. Provenance:
self-review, report version 2, 2026-10-24; no unseen
controls or external examples were used.
