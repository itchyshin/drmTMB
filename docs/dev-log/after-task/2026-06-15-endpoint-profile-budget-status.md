# After Task: Endpoint Profile Budget Status

## Goal

Make the native `drmTMB` profile-status path more honest for Ayumi-style q4
checks before returning to Julia speed work. A long endpoint profile should be
able to stop after a deliberate evaluation budget and return a row-level status
that downstream harnesses can record.

## Implemented

- Added `profile_endpoint_max_eval` to `confint.drmTMB()` for direct scalar
  endpoint profiles.
- Kept default behaviour unchanged: without the budget, `profile_engine =
  "auto"` can still use the endpoint solver first and fall back to the existing
  full-profile route where appropriate.
- When the budget is supplied and reached, `confint()` returns an endpoint
  `profile_failed` row with missing endpoints and an evaluation-budget message.
- Extended `tools/ayumi-q4-status-harness.R` with
  `DRMTMB_AYUMI_Q4_PROFILE_ENDPOINT_MAX_EVAL`.
- Added `fit_diagnostic_status` to the harness fit table so returned fits with
  `convergence != 0` or `pdHess = FALSE` are not confused with inference-ready
  fits.
- Updated NEWS, the generated `confint()` help page, the finish matrix, the
  mission-control JSON source, and the check-log.

## Verification

```sh
air format R/profile.R tests/testthat/test-profile-targets.R tools/ayumi-q4-status-harness.R
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); devtools::test(filter = "profile-targets")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); set.seed(20260682); n <- 60; x <- stats::rnorm(n); dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7), x = x); fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat); ci <- stats::confint(fit, parm = "sigma", level = 0.80, method = "profile", profile_endpoint_max_eval = 1); stopifnot(identical(ci$profile.engine, "endpoint"), identical(ci$conf.status, "profile_failed"), is.na(ci$lower), is.na(ci$upper), grepl("evaluation budget", ci$profile.message)); cat("endpoint budget status check passed\n")'
python3 tools/validate-mission-control.py
```

The profile-target file passed with 773 expectations. The dashboard validator
reported `mission_control_ok: 15/65 banked_or_verified, 3 active, 16 matrix
rows`.

The Ayumi-bundle smoke used the real `for_test/` RDS at 250 tips:

```sh
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_SIZES=250 \
DRMTMB_AYUMI_Q4_ENGINES=tmb \
DRMTMB_AYUMI_Q4_REML=false \
DRMTMB_AYUMI_Q4_PROFILE=first_sigma \
DRMTMB_AYUMI_Q4_PROFILE_ENDPOINT_MAX_EVAL=1 \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-q4-status/profile-budget-250 \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

It wrote a returned native ML fit row with `convergence = 1`, `pdHess = FALSE`,
and `fit_diagnostic_status = "fit_returned_nonconverged_pdhess_false"`. It also
wrote an endpoint interval row with `conf.status = "profile_failed"` and the
evaluation-budget message.

## Claim Boundary

This is status hardening, not a speed fix. It does not make native
`engine = "tmb"` a full REML fallback for the bivariate q4 phylogenetic
location-scale model, and it does not show that full 10,440-tip profile
intervals are practical. A subprocess watchdog remains a later harness slice if
we need a row for profile attempts that never return from compiled code.
