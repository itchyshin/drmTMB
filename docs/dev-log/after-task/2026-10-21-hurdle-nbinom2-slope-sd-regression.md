# After Task: Hurdle NB2 Independent-Slope SD Regression

## 1. Goal

Add one native hurdle NB2 route for a predictor-dependent SD on an ordinary independent location slope, then record its recovery and workflow evidence without extending the broader programme claim.

## 2. Implemented

For complete responses, hurdle NB2 now accepts one ordinary `mu` intercept with or without an SD formula, or one independent numeric `mu` slope when that slope has a matching direct `sd()` formula. The scale predictor must be constant within the grouping factor. The selected scale row follows the random-effect coefficient through fitting, prediction, simulation, and save/reload.

For the slope route, the synthetic data use `b_g ~ Normal(0, tau_g^2)`, with `log(tau_g) = alpha_0 + alpha_1 z_g`; the group slope contributes `b_g x_ig` to the NB2 log mean. Hurdle zeros remain governed by the fixed-effect `hu` component. The same latent location effect enters the positive-count NB2 density and its zero-truncation normalizer.

The fitted scale is `tau_g = exp(alpha_0 + alpha_1 z_g)`. It is the among-group SD of the random slope. `hu` remains the probability of a structural zero; the direct SD formula changes the positive-count component. No free Bernoulli-style residual scale or random effect on `hu` is added.

## 3a. Decisions and Rejected Alternatives

The implementation reuses the current hurdle likelihood term loop, which already selects the scale row for each location term. No C++ edit was needed, and the shared C++ path remains under separate active-lane coordination. The new slope route is limited to one selected independent coefficient; this follows the existing scalar-target metadata and avoids adding correlated or multi-term covariance behavior. Assumption: this bounded slice should cover an independent slope rather than an intercept-plus-slope block. If that assumption changes, the broader block route needs its own design and tests.

Memory receipt: I searched the vault first and read D-93 on the release and interval-coverage boundary; it did not expand this implementation slice. `route.py` found no LOAD-FIRST manifest for the supplied worktree path. The repository remains the technical source of truth. Golden Set: not run because this slice did not investigate a routed known-mistake class.

## 4. Files Touched

- `R/drmTMB.R`: admit one selected slope target only when its matching direct SD model is present.
- `tests/testthat/test-hurdle-nbinom2-sd-regression.R`: add assembly and seeded point-recovery, prediction, simulation, and save/reload checks.
- `tests/testthat/test-hurdle-nbinom2.R`: update unsupported-route assertions for the admitted slope boundary.
- `tests/testthat/test-truncated-nbinom2-sd-regression.R`: retain the separate zero-truncated boundary checks.
- `vignettes/count-nbinom2.Rmd`: document the hurdle intercept and selected-slope routes and their boundaries.
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`: record the native family adapter and evidence boundary.
- `docs/dev-log/check-log.d/2026-10-21-hurdle-nbinom2-slope-sd-regression.md`: record the test and render results.
- `LOOP/lanes/general-sd-regression/arcs.md` and `LOOP/lanes/general-sd-regression/checkpoint.md`: record programme progress and its limits.
- `docs/dev-log/after-task/2026-10-21-hurdle-nbinom2-slope-sd-regression.md`: this report.

No C++ change was made for this slice. The existing hurdle likelihood loop already applies the selected scale row to each location term. The shared C++ source also has separate active-lane edits, so this slice stayed in the owned R, test, and vignette paths.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^(hurdle-nbinom2-sd-regression|hurdle-nbinom2|truncated-nbinom2-sd-regression)$")'`: 119 expectations passed, with 0 failures, warnings, or skips, in 68.9 seconds. No live Julia engine test ran. The test session printed the package's one-time `simulate()` convention notice.
- `Rscript -e 'rmarkdown::render("vignettes/count-nbinom2.Rmd", quiet = TRUE)'`: rendered successfully; Pandoc reported that `--mathjax` is deprecated.
- `git diff --check -- R/drmTMB.R tests/testthat/test-hurdle-nbinom2.R vignettes/count-nbinom2.Rmd LOOP/lanes/general-sd-regression/arcs.md LOOP/lanes/general-sd-regression/checkpoint.md`: passed.
- `python3 ~/shinichi-brain/tools/slop_check.py <this report>`: 0 style findings.
- `/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R <this report>`: report structure passed. Its programme-wide ledger recheck returned 11 unmet gates: the parent ledger plus `binomial-selectors`, `julia-bernoulli-q2-bridge-dpars`, `lognormal-intercept`, `native-binomial`, `native-student-slope-sd`, `ordinary-targets`, `poisson-label`, `poisson-ordinary`, `poisson-slope`, and `student-slope-julia-bridge`. This bounded slice does not close those gates or the programme.
- `/Users/z3437171/Dropbox/Github Local/Shinichi/tools/closeout.py check <this report>`: closeout compiler stopped because the same programme-wide ledger gates remain unmet.
- A read-only GitHub search for `hurdle NB2 random slope SD` found no dedicated open issue. No issue action was needed.

## 6. Tests of the Tests

The new assembly test first failed at the existing intercept-only builder guard when the selected slope formula was introduced. After the builder admitted only the matching `sd()` case, the complete affected test set passed. The recovery test uses an independent seeded DGP with a nonzero SD-predictor coefficient and checks point recovery, a positive-definite Hessian, group-level SD prediction, simulation, and save/reload.

## 7a. Issue Ledger

Searched all GitHub issue states for `hurdle NB2 random slope SD`. The returned results were #1463, an unrelated October test-sweep issue, and #761, an unrelated missing-response issue. No matching issue existed, so no issue was opened, edited, or closed.

## 8. Consistency Audit

An independent reviewer found and corrected one vignette sentence that could imply a slope was accepted without an SD formula. The count vignette now states that the intercept may be used without SD regression, while a slope requires its matching scale formula. The formal grammar rows in `docs/design/01-formula-grammar.md` and `vignettes/formula-grammar.Rmd` still describe only the intercept route. `lane_preflight.sh --file` reported 65 and 46 absent refs for those two files, respectively, so they were left untouched. The first NEWS entry and current known-limitations text also describe only the intercept route; the NEWS preflight reported 207 absent refs. These shared descriptions need coordinated reconciliation after their diffs and owners are resolved. The exact scan `rg -n 'hurdle.*(ordinary|independent|random slope|SD regression)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md` found no claim that the new slope route is already generally available.

## 9. What Did Not Go Smoothly

The worktree contains broad in-flight changes, and the common design files have many divergent ref versions. This prevented a safe update of the formal grammar table in this slice. A reviewer also caught the vignette wording mismatch before this report was written. The targeted render emitted a Pandoc deprecation warning but completed.

## 10. Known Residuals

The native TMB evidence covers point recovery for one ordinary hurdle NB2 `mu` coefficient at a time. Julia parity, interval coverage, correlated or multiple terms, structured effects, missing-response behavior, random effects on `hu` or `sigma`, and profile/bootstrap interval validity remain unverified. Formal grammar and design tables still need a coordinated update. The full general-SD goal remains open.

## 11. Team Learning

When an adapter admits a random slope only alongside a selected SD model, state that dependency in the first capability sentence and test the slope-without-SD rejection beside the positive route. The independent review caught the gap between builder behavior and prose before the example could mislead users.

## 12. Cross-Product Coverage

For the native TMB hurdle NB2 route, this slice covers one complete-data ordinary `mu` intercept and one independently selected numeric slope with a matching direct SD formula. The tests cover assembly, seeded slope point recovery, group-level SD prediction, simulation, save/reload, and unsupported neighboring inputs. It does NOT cover Julia fitting, other families, other random-effect providers, correlated or multiple coefficients, `hu` or `sigma` random effects, missing responses, interval calibration, or any cross-engine parity claim. The shared grammar and NEWS descriptions also remain incomplete pending coordinated ownership review.

The next action is to continue with the next unfilled capability cell in the approved general-SD ledger while preserving these exclusions.
