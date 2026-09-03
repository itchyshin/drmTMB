# N8 -- bootstrap CIs for cbind(successes, failures) binomial fits (issue #1123)

## 1. Reader and scope

Reader: a `drmTMB` maintainer verifying arc N8 of the overnight lane closed
issue #1123 correctly and did not touch anything outside its fence. Arc N8
fixes `bootstrap_response_data()` (`R/profile.R`) so that
`confint(fit, method = "bootstrap")` works for binomial fits whose response
uses trial-denominator syntax, `bf(cbind(successes, failures) ~ x)`. Worked
in the dedicated `wt-n8` worktree, branch `claude/night-n8-bootstrap-cbind`,
off `origin/main` `d3d205486`. No pushes made, no PR opened.

## 2. The failure on main

`confint(fit, method = "bootstrap")` on a `bf(cbind(s, f) ~ x)` binomial fit
errored on every replicate:

```
Error in `bootstrap_response_data(object, simulations, index)`: Bootstrap
confidence intervals require a stored response column in the fitted data.
```

`method = "wald"` and `method = "profile"` worked on the same fit; only the
bootstrap route was broken.

## 3. Mechanism

`bootstrap_response_data()` writes the current bootstrap replicate's
simulated response back into a copy of the fitted data before refitting. For
a single-column response it looks up the response's column name via
`response_name_from_model_frame()`, which for a `cbind()` term returns
`names(model.frame(...))[[1]]` -- and R's own `model.frame()` names a
two-column `cbind(s, f)` model-frame column literally `"cbind(s, f)"`, not
`"s"` or `"f"`. That string is never a column of the original data
(`object$data` has separate `s` and `f` columns), so the function's own
"is this name in the data?" guard tripped and aborted, on every family that
takes a `cbind()` response, before ever checking the family. The bivariate
Gaussian/lognormal branch above it already special-cased its own two-column
response for the same reason; the binomial `cbind()` case had no equivalent
branch.

`simulate.drmTMB()`'s binomial branch (`R/methods.R`) already draws the
correct thing regardless of how the original response was encoded: it calls
`stats::rbinom(n, size = object$model$trials, prob = mu)` and returns one
`sim_<index>` column of simulated **success counts** per replicate,
constrained to each row's fitted `trials`. The missing piece was only on the
write-back side.

## 4. Fix

Added a `model_type == "binomial"` branch to `bootstrap_response_data()`,
gated on `object$model$denominator$encoding == "cbind(successes, failures)"`
(set at fit time in `R/drmTMB.R`'s `prepare_binomial_response()`, alongside
`success_name`/`failure_name`/`trials`, only for the two-column syntax). For
that case the function now rebuilds both response columns from the
simulated successes and the row's own fitted trial size:

```r
successes <- simulations[[sim_col]]
data[[denominator$success_name]] <- successes
data[[denominator$failure_name]] <- denominator$trials - successes
```

`success_name`/`failure_name` are the literal data column names supplied to
`cbind()` (e.g. `s`/`f`), not the synthetic `"cbind(s, f)"` model-frame
label, so the write-back lands on the columns the refit's own `cbind()`
formula will read. Bernoulli 0/1 fits (`encoding == "0/1"`) and any other
single-column family fall through unchanged to the pre-existing generic
path -- the new branch only fires when `denominator$encoding` is exactly
`"cbind(successes, failures)"`.

## 5. Tests (`tests/testthat/test-bootstrap-cbind.R`, new)

- `"bootstrap confint works for cbind(successes, failures) binomial fits"`:
  fits `bf(cbind(s, f) ~ x)` on n = 60 synthetic rows (`trials` 5-20 per
  row), calls `confint(fit, method = "bootstrap", R = 15, seed = ...)` on
  the two fixed-effect targets, asserts both `conf.low`/`conf.high` are
  finite for every target. Reproduced the exact #1123 error on main before
  the fix; passes after.
- `"bootstrap_response_data keeps each row's trial size for cbind binomial
  fits"`: calls `drmTMB:::bootstrap_response_data()` directly for several
  bootstrap indices against `stats::simulate(fit, nsim = 5, seed = ...)`,
  asserts `resampled$s + resampled$f` equals the original `dat$trials`
  vector for every index.

## 6. RED CONTROL (gate N8-G2)

With the fix in `R/profile.R` stashed (`git stash push -- R/profile.R`),
the same test file reproduces the identical #1123 error text on both test
blocks (see backtrace ending in
`cli::cli_abort("Bootstrap confidence intervals require a stored response
column in the fitted data.")` at the old `bootstrap_response_data()` line).
The stash was popped immediately after and `git diff origin/main --
R/profile.R` confirmed non-empty (fix present) with the tree otherwise
clean.

## 7. Deviation from the task sketch

The task brief suggested `bf(cbind(s, f) ~ x, sigma ~ 1)`-style syntax.
Binomial fits in `drmTMB` do not take a `sigma` formula (the binomial model
spec's only distributional parameter is `mu`; see `dpars = "mu"` in
`R/drmTMB.R`'s binomial spec builder) -- other binomial tests in the suite
(`tests/testthat/test-binomial-response.R`) confirm this. The test instead
uses `bf(cbind(s, f) ~ x)`, matching the package's actual binomial syntax
and the `plain_binomial_nonphylo` capability row the issue cites.

## 8. What this does NOT cover

- **RNG same-seed design**: unchanged. This fix does not touch how
  `stats::simulate()` draws bootstrap replicates or how `seed` is applied;
  the open P2 same-seed question referenced in the ledger is untouched.
- **Julia-engine bootstrap**: this fix is R-side only (`R/profile.R`); no
  `DRM.jl` file was read or touched, and Julia-backed bootstrap CIs (if any
  exist) are out of scope.
- **`beta_binomial` (and any other two-column-response family)**: the
  `beta_binomial` model type also parses a `cbind(successes, failures)`
  response (`prepare_betabinomial_response()` in `R/drmTMB.R`) and its
  `simulate.drmTMB()` branch also returns a single simulated-count column,
  so `bootstrap_response_data()`'s generic path likely has the identical
  defect for `beta_binomial` fits. This was not fixed or tested here: issue
  #1123 and the N8 gate ledger scope the fix and its acceptance tests to
  `model_type == "binomial"` only. A `beta_binomial` fit hitting the same
  `cli_abort()` is a plausible follow-up issue, not silently claimed fixed
  by this change.
- **Bernoulli 0/1 and proportion-with-weights paths**: intentionally left
  byte-identical -- the new branch only fires when
  `denominator$encoding == "cbind(successes, failures)"`; every other
  binomial encoding, and every non-binomial family, falls through to the
  unchanged pre-existing code.

## 9. Verification

- `tests/testthat/test-bootstrap-cbind.R`: 6 expectations across 2 blocks,
  0 failed / 0 error / 0 skipped (`devtools::load_all()` +
  `testthat::test_file()`).
- Regression sweep over every `test-*bootstrap*|profile*|confint*.R` file
  in `tests/testthat/`: 0 failed, 0 error across all files (one pre-existing
  unrelated skip in `test-profile-targets.R`, not introduced by this
  change).
- RED CONTROL: fix stashed -> identical #1123 error reproduced; fix
  restored -> tree clean except the intended `R/profile.R` diff.
- `git diff --name-only origin/main -- R` == `R/profile.R` only.
