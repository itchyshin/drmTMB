# After task: fit-free tests for the profile argument validators

## What changed

- New `tests/testthat/test-profile-arg-validators.R` (test-only). It calls the
  internal validators in `R/profile.R` directly with `drmTMB:::`, no model fit:
  `validate_interval_method()`, `resolve_profile_precision()`,
  `resolve_bootstrap_parallel()`, `validate_profile_maxit()`,
  `validate_profile_plot_flag()`, `profile_first_pass_args()` and
  `validate_profile_plot_data()`.
- The tests characterise current behaviour; no file under `R/` changed.

## Behaviour recorded (findings, none are bugs)

- `validate_interval_method()` takes the first choice when a length > 1 vector
  lies wholly inside `choices`, and aborts "must be a single character value"
  otherwise. The `bootstrap` / `parametric_bootstrap` refusal fires only on the
  exact strings and only when they are not in `choices`; partial forms such as
  `"param"` fall through to the generic "must be one of" error.
- `profile_first_pass_args()` sets `ystep` and `ytol` but also drops `maxit`
  from the returned list (`out$maxit <- NULL`). This is intended (first pass
  uses the TMB default) and is asserted explicitly; all other elements are
  unchanged.
- `resolve_profile_precision()` and `resolve_bootstrap_parallel()` ignore the
  supplied value when `missing_arg` is TRUE.

## Verification

- `pkgload::load_all(); testthat::test_file("tests/testthat/test-profile-arg-validators.R")`:
  FAIL 0, WARN 0, SKIP 0, PASS 108.
- No skips, so `inst/extdata/env-skip-census.tsv` is untouched. Existing test
  files, `NEWS.md` and `DESCRIPTION` are untouched.
