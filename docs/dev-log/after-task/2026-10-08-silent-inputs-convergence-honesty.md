# After Task: Silent inputs and convergence honesty

The absolute `1e-8` gradient verdict in this note was replaced after review.
Read `2026-10-08-review-scale-free-gradient.md` for the Newton-step rule,
the `cbind()` factor check, and the QQ envelope grid.

Reader: an applied ecology or evolution user who fits one or two responses,
and a package contributor checking that a code-0 fit and a QQ plot mean what
they appear to mean.

## Goal

Stop three silent failures. A factor response must not be fitted as integer
level codes (#1481). A quantile residual at `u = 0` or `u = 1` must not
disappear from `qq_plot()` / `worm_plot()` without a count (#1460).
`is_converged()` must not stay `TRUE` when the stored gradient is above the
Newton-polish tolerance (#1452).

## Implemented

`drm_reject_factor_response()` aborts, names the column, and tells the user
to convert the column to numeric so the recorded numbers are fitted, not the
level indices. The guard runs before `as.numeric()`, `round()`, and
`is.finite()` in the Gaussian, Student-t, skew-normal, lognormal, Gamma,
Tweedie, beta, zero-one beta, Poisson, nbinom2, and truncated-nbinom2
builders, including the hurdle route, and in `biv_gaussian`,
`biv_lognormal`, and `biv_student`. The same guard runs on the Julia bridge
payload, both structured Julia data routes, and the cross-family Julia axis.
`cumulative_logit()` still accepts an ordered factor. Binomial already
refused a factor. A character column is still coerced.

`qq_plot()` and `worm_plot()` share `drm_quantile_residual_qq_from_matrix()`.
Non-finite residuals stay off the order-statistic grid. The function warns
with class `drmTMB_quantile_residual_warning`, stores
`n_nonfinite_quantile_residuals`, and the subtitle repeats the count.
Missing-response `NA` rows are not in that count. `residuals(type =
"quantile")` already returned `Inf`; only the plot table had dropped those
points quietly. Clamping was not used, because putting `+/-Inf` on the plot
would move every theoretical quantile.

`DRM_NEWTON_GRAD_TOL` is `1e-8`. `convergence_status()` returns `"gradient"`,
and `is_converged()` is `FALSE`, when the stored gradient is non-finite or
`max(abs(gradient))` exceeds that tolerance. The status function reads
`object[["gradient"]]`. `$` would partial-match `gradient_max_component` and
treat the component name as a non-numeric gradient. A failed `obj$gr()` is
stored as `NA_real_`, not `NULL`, so a hand-built object with no gradient
field is still graded as before. Fit time warns with class
`drmTMB_gradient_warning` and names the largest component. The Newton update
itself is unchanged, so coefficients do not move. `check_convergence_status()`
maps `"gradient"` to a warning row.

## Mathematical Contract

No likelihood, link, or coefficient parameterization changed. Location is
`mu`, scale is `sigma`, and residual correlation is `rho12`. The new
`"gradient"` status is a statement about the stored score at the reported
optimum, not a new estimator. The QQ change does not alter the finite order
statistics: the theoretical quantiles are still `qnorm(ppoints(m))` on the
finite residuals only.

## Files Changed

- `R/drmTMB.R`, `R/check.R`, `R/adequacy.R`, `R/adequacy-plots.R`,
  `R/julia-bridge.R`
- `tests/testthat/test-factor-response.R`,
  `tests/testthat/test-quantile-residual-nonfinite.R`,
  `tests/testthat/test-fit-convergence-warning.R`,
  `tests/testthat/test-adequacy.R`
- `NEWS.md`, `man/is_converged.Rd`, `man/convergence_status.Rd`,
  `man/qq_plot.Rd`, `man/worm_plot.Rd`,
  `tools/function-cheatsheet-source.Rmd`,
  `docs/dev-log/known-limitations.md`, `docs/dev-log/check-log.md`

Rd files were edited by hand. Installed roxygen2 is 7.3.1 and
`RoxygenNote` is 7.3.2, so a full roxygenise was not run.

## Checks Run

R 4.3.3, TMB 1.9.10, ggplot2 3.4.4, testthat 3.2.1, tweedie 3.1.0.
`NOT_CRAN=true`, `OPENBLAS_NUM_THREADS=1`.

Focused suite, 39 files (family builders that received the guard, plus
convergence, diagnostics, adequacy, and plot files): 4950 expectations
passed, 0 failed, 6 skipped, 19 errors. All 19 errors are
`test-julia-diagnostics.R`: `could not find function "%||%"` inside
pre-existing `new_drmTMB_julia()` (`R/julia-bridge.R` around the
`estim_method` line, unchanged in this diff). Two of the six skips were
tweedie adequacy tests in a process that could not see the user library.

Re-ran `test-adequacy.R` with tweedie visible, after expecting the
mis-specified Gaussian warning: 23 passed, 0 failed, 0 skipped, 0 warnings.
`test-factor-response.R` after the Julia guard test: 24 passed, 0 failed.
`test-quantile-residual-nonfinite.R`: 16 passed.
`test-fit-convergence-warning.R`: 31 passed.

Plot files in the suite: `test-plot-corpairs.R` 48 passed,
`test-plot-parameter-surface.R` 46 passed, `test-profile-plots.R` 52 passed.
Their warnings are pre-existing ggplot2 `inherit.aes` messages, not the new
quantile-residual warning.

An ordinary seed-1 Gaussian fit (`n = 40` and `n = 60`) stored a gradient
below `1e-8` (`3.12e-13` and `1.68e-12`) and stayed `"converged"`. Fits that
now warn, and whose tests still pass, include a bivariate phylogenetic
gradient of `5.51e-8`, a q4 block at `1.44e-8`, a truncated nbinom2 intercept
at `3.43e-8`, and a zero-one beta `beta_zoi` at `1.59e-8`.

## Tests Of The Tests

The factor test failed before `biv_gaussian()` was used, because
`family = gaussian()` with `mu1` / `mu2` never reached the bivariate builder.
The QQ test failed before the matrix columns had equal length, and again
because testthat edition 3 returns the warning condition from
`expect_warning()`, not the data frame. The convergence test failed while
`fit$gradient <- NULL` was read back through `$` as
`gradient_max_component`. Each of those failures was in the new test, and
each is fixed in the code or the test without relaxing an existing
assertion. The Fig-4c adequacy test now expects the non-finite warning on
the location-only fit and still requires the cubic R-squared gap.

## Consistency Audit

```sh
rg -n "meta_gaussian|tau ~" README.md NEWS.md docs/dev-log/known-limitations.md \
  docs/design/01-formula-grammar.md vignettes
```

The only hits are the intentional statements that there is no `tau ~`
formula and no `meta_gaussian()` family (`vignettes/which-scale.Rmd`,
`vignettes/meta-analysis.Rmd`). Formula grammar and likelihood design notes
were not edited: this change does not add a family or a formula term.
Historical parity notes that mention `is_converged()` were left as records
of earlier fits.

## GitHub Issue Maintenance

No issue was closed. `Fixes #1481`, `Fixes #1460`, and `Fixes #1452` belong
on the draft PR because each issue's requested user-visible guarantee is
implemented. #1483 stays open: Julia `is_converged()` still ignores
`include_hessian` and the stored gradient. No comment was posted on the
issues.

## What Did Not Go Smoothly

`graft` is not installed in this environment, so the builders were found by
reading call sites rather than from the graph. `test-julia-diagnostics.R`
cannot construct a mock Julia fit here because `%||%` is not visible in the
drmTMB namespace; that failure is older than this branch.

## Team Learning

Name a new fit field so it does not partially match an existing one under
`$`. `gradient_max_component` is a partial match for `gradient`. The Julia
diagnostics code already used `[[` for that reason. The native status
function now does too.

## Known Limitations

Character responses are not rejected. `beta_binomial()` still errors when
the response is not a two-column matrix, which is a different message.
`qq_plot()` / `worm_plot()` do not draw the non-finite points; they count
them. If `nsim > 1` drops a different number of points from each column, the
envelope compares different theoretical quantiles. Julia `is_converged()`
does not apply `1e-8`. `multi_start` still picks the lowest objective.
`check_fixed_gradient()` still recomputes a live gradient at `1e-3`.
`profile()` polish does not emit the fit-time gradient warning. The
`methods.R` `report()` error path and the log-sigma clamp detector were
left unchanged. Phase 18's replicate runner does not copy
`drmTMB_gradient_warning` into the failure ledger, matching the existing
treatment of `drmTMB_convergence_warning`. CI on the first push failed
four phase18 grid-writer expectations because that warning was counted as
a replicate failure (`test-phase18-biv-gaussian-q8-endpoint.R`,
`test-phase18-biv-gaussian-q6-location.R`,
`test-phase18-animal-relmat-q4-grid-writer.R`).

## Ledger

`python3 tools/recertify-c17.py --label silent-inputs --tolerance 2e-11`
on commit `ac0491e40`. `mean_tau_relative_error` moved by `3.030e-12`
(mc-0568), `1.322e-11` (mc-0569), and `5.263e-12` (mc-0576). The worst
change matches the float noise previously measured on unchanged `main`.
The zero-one-beta builder text now contains the factor abort, so the
model-15 source fingerprint moved; the likelihood did not. Receipt:
`docs/dev-log/implementation-recovery/2026-10-08-silent-inputs-c17c2-c14-final-source-compatibility`.
`python3 tools/capability_ledger.py --check` passed.

## Next Actions

Watch CI on the draft PR. Do not merge.
