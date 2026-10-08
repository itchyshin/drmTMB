# 2026-10-08: three numeric and Julia-bridge bugs

Reader: an applied user who fits Student-t, cloglog, or truncated NB2 models, and a package contributor who reviews the Julia bridge.

## Task goal

Stop three silent numerical failures. A univariate Student log-likelihood must not climb above the Gaussian limit as `nu` grows. `drm_log1mexp()` must keep both automatic-differentiation branches finite, so a cloglog Hessian is not `NaN` when a success probability is far below `1e-16`. A Julia-engine fit must not pair different rows when each response has an `NA` in a different place.

## What changed

`drm_student_log_density()` in `src/drm_response_kernels.h` still uses

```text
lgamma((nu+1)/2) - lgamma(nu/2) - 0.5 log(nu pi) - log(sigma)
  - ((nu+1)/2) log(1 + z^2/nu)
```

for `nu < 1e4`. At and above `1e4` the constant is the Stirling series in `a = nu/2`,

```text
-0.5 log(2 pi) - 1/(8a) + 1/(192 a^3) - 1/(640 a^5)
```

and the kernel is `drm_log1p_nonnegative(z^2/nu)`. `logLik()` reads this TMB objective. There is no second R formula. `fitted_distribution()` already calls `stats::dt()`.

`drm_log1mexp()` and `drm_log1p_nonnegative()` in `src/drm_numeric.h` clamp each branch's argument into the region where that branch is finite. The selected value and its first derivative stay the ones the old code computed. Clamping the input before the series would have moved a cloglog `log(mu)` off `eta`.

Cross-family Julia axes compare the row index kept by `na.omit`, not the length of what remains. A sigma design must keep the same rows as its location axis. Structured `response = "drop"` now drops incomplete rows and errors if that would remove a grouping level from the covariance. Bivariate q2 structured payloads error when a modelled column contains `NA`. The main bridge stores the drop count, and `check_drm()` prints a `dropped_rows` row when that slot is present. `response = "include"` still passes the supplied rows through.

`R/zzz.R` defines `%||%`. Base R added that operator in 4.5.0, and this package allows R >= 4.1. The Julia bridge, its diagnostics, and the MSPL link code already called it.

## Files

- `src/drm_response_kernels.h`, `src/drm_numeric.h`
- `R/julia-bridge.R`, `R/julia-diagnostics.R`, `R/zzz.R`
- `tests/testthat/test-student-large-nu.R`, `test-log1mexp-ad.R`, `test-julia-missing-alignment.R`
- `tests/testthat/test-guard-branch-continuity.R`, `test-julia-diagnostics.R`
- `docs/design/03-likelihoods.md`, `NEWS.md`, this report, `docs/dev-log/check-log.md`

`src/drmTMB.cpp`, `R/drmTMB.R`, and `R/methods.R` were not edited. The C14/C17 fingerprint covers sections of those two R and C++ files only, so it was not recertified. The header edits are outside that hash.

## Checks

Local R 4.3.3. The package was installed with `R CMD INSTALL` into `/workspace/.Rlib` after the C++ edit. The final green union of the related files is 179 tests, 0 failures, 17 skips, 1488 expectations.

| File | Tests | Failed | Skipped | Expectations |
| --- | ---: | ---: | ---: | ---: |
| test-student-large-nu.R | 2 | 0 | 0 | 23 |
| test-log1mexp-ad.R | 2 | 0 | 0 | 26 |
| test-julia-missing-alignment.R | 6 | 0 | 0 | 20 |
| test-student-location-scale.R | 6 | 0 | 0 | 47 |
| test-numeric-kernel-oracle.R | 19 | 0 | 0 | 392 |
| test-biv-student.R | 8 | 0 | 0 | 67 |
| test-missing-predictor-student-response.R | 4 | 0 | 0 | 17 |
| test-phase18-student-shape-summary-smoke.R | 3 | 0 | 0 | 34 |
| test-guard-branch-continuity.R | 14 | 0 | 0 | 59 |
| test-binomial-links.R | 9 | 0 | 1 | 66 |
| test-binomial-response.R | 5 | 0 | 0 | 60 |
| test-hurdle-nbinom2.R | 6 | 0 | 0 | 60 |
| test-truncated-nbinom2-location-scale.R | 8 | 0 | 0 | 78 |
| test-julia-missing.R | 8 | 0 | 5 | 5 |
| test-julia-diagnostics.R | 22 | 0 | 2 | 123 |
| test-xfam-bridge.R | 12 | 0 | 6 | 43 |
| test-julia-bridge.R | 16 | 0 | 2 | 139 |
| test-julia-structured.R | 9 | 0 | 1 | 59 |
| test-julia-joint-missing.R | 7 | 0 | 0 | 39 |
| test-missing-response-boundary.R | 5 | 0 | 0 | 96 |
| test-missing-response-boundaries.R | 3 | 0 | 0 | 18 |
| test-missing-response-family-gate.R | 2 | 0 | 0 | 2 |
| test-missing-data-control.R | 3 | 0 | 0 | 15 |

Skips are live Julia routes without `DRM_JL_PATH`, or the binomial extreme-probability case gated by `NOT_CRAN`. The Student, cloglog, and truncated-NB checks evaluate `obj$fn()`, `obj$gr()`, and `obj$he()` and require a finite gradient and Hessian. No Julia process was started.

The first pass of `test-numeric-kernel-oracle.R` failed its tweedie comparison because `{tweedie}` was not installed (`ref` was all `NA`). After `install.packages("tweedie")` the same file passed 19 tests and 392 expectations. `{mvtnorm}` was installed for the bivariate Student oracle, which then passed with no skip.

`python3 tools/capability_ledger.py` was not asked to rewrite a receipt. `tools/ci-receipt-staleness.sh` hashes every `R/*.R` for `lss-tip-identity`. This change touches `R/julia-bridge.R`, `R/julia-diagnostics.R`, and `R/zzz.R`, so that receipt goes stale when the branch merges to `main`. Regenerating it needs a live Julia pin. The workflow runs on push to `main`, not on pull requests. The hashes were not invented.

Stale-wording searches, with no contradictory hit in the current user docs:

```sh
rg "meta_gaussian|tau ~|rho ~" README.md NEWS.md docs/design/03-likelihoods.md
rg "lgamma\(\(nu" docs/design/03-likelihoods.md
```

The symbolic Student density in `docs/design/03-likelihoods.md` is still the textbook expression. The paragraph above it now says which evaluation is used for large `nu`.

## Consistency

The bivariate Student density (`model_type` 20) already reduces the lgamma difference to `-log(2 pi)` and already calls `drm_log1p_nonnegative`. `src/drmTMB.cpp` was left untouched so the C17 pin stays fresh. Call sites of `drm_log1mexp` in that file (cloglog through `drm_binom_log_mu`, zero-truncated NB2, hurdle NB2, and the ordinal interval) pick up the header fix without an edit.

Named and not rewritten:

- Beta, zero-one-beta, and beta-binomial `lgamma(alpha+beta) - lgamma(alpha) - lgamma(beta)` at huge phi. That is a different boundary from the Student constant.
- `drm_nbinom2_log_count_product()` still chooses a series against an lgamma ratio with `CondExp`. The series coefficients are delicate, so that site was not retaped.
- Binomial `lgamma` choose terms are integer combinatorics.
- `ordinal_log1mexp()` in `R/methods.R` is plain R (`log1p` / `expm1`), not an AD tape.
- The main Julia route and the phylogenetic route already drop with one complete-case index. This change records that count. It does not add a second filter.

## Tests of the tests

The Student regression compares the compiled objective with `stats::dt()` from `nu = 10` through `eta_nu = 55`, and requires the excess over the Gaussian density at the same `mu` and `sigma` to stay below `1e-4` once `nu >= 1e6`. A fitted Student model on Gaussian data may beat the Gaussian fit by a fraction of a nat, because `nu` is a free shape parameter. The assertion rejects an excess of 2 nats. The bug reported excesses near `1e11`.

The cloglog regression checks five successes at `eta` in `{-30,-37,-40,-60}`. The negative log-likelihood stays within `1e-4` of `-5 * eta`, and the Hessian is finite. A zero-truncated NB2 grid does the same at `eta_mu` in `{-37,-38,-44}`.

The Julia regression does not start Julia. It calls `drm_julia_xfam_axes()`, `drm_julia_drop_structured_missing()`, and `drm_julia_biv_known_structured_payload()` and expects an error for disagreeing `NA` patterns, a lost grouping level, and an incomplete q2 response.

## What did not go smoothly

Ubuntu's R is 4.3.3, so the pre-existing `%||%` calls in the Julia bridge failed with "could not find function" until the package defined the operator. The first Student bound compared the density with the Gaussian density at the same `sigma` for every `nu`. Around `nu = 1e4` the true Student density is about `0.001` nats above that Gaussian on the test data, because the peak is sharper. The bound now applies once `nu >= 1e6`, which is where the cancellation bug appeared.

`{fs}` needed `libuv1-dev` before `{testthat}` would install. `{tweedie}` was absent on the first oracle run.

## Behaviour changes

- Student fits with `nu` above about `1e4` to `1e6` can move. The old objective in that region was rounding noise. Moderate `nu` stays on the lgamma branch and matches the previous `dt()` oracle.
- Cloglog, truncated NB2, hurdle NB2, and ordinal-interval likelihood values are unchanged. Hessians that were `NaN` at the extreme edge become finite.
- Cross-family Julia fits whose responses are missing on different rows now error. Shared complete cases still fit.
- Structured Julia `response = "drop"` now drops incomplete rows. Estimates can change relative to the old path, which forwarded `NA` and could return `NaN`. Losing a whole grouping level is now an error.
- q2 structured Julia fits with `NA` in a modelled column now error.
- `check_drm()` on a Julia fit that went through the drop filter gains a `dropped_rows` row. A drop of one or more rows is a note and does not flip `attr(ok)`. Mocks without the slot are unchanged. `response = "include"` is unchanged.
- On R before 4.5, Julia formula marshalling, bridge diagnostics, and the MSPL link code no longer error on `%||%`.

## Issue maintenance

No issue was closed from this working tree. The draft pull request uses `Fixes #1462`, `Fixes #1472`, and `Fixes #1454`. Open PRs #1500 and #1443 mention those issues and do not fix them.

## Known limitations

Beta and NB2 lgamma ratios at extreme dispersion are still the expressions named above. Cross-family Julia fits still have no per-axis missingness model. The next step for a user who needs different missing rows on the two responses is to drop to one complete-case index before calling `drmTMB()`, or to fit with `engine = "tmb"`.
