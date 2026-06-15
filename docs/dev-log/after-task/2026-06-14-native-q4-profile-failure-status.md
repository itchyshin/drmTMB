# After Task: Native q4 Profile Failure Status

## Goal

Unblock the first native-TMB fallback slice from #551 by making boundary-aware
profile attempts report useful row-level status, and by pinning the bivariate
q=4 phylogenetic location-scale target inventory that Ayumi's benchmark needs.

## Implemented

`confint(method = "profile")` now catches numeric failures from both direct
endpoint profiling and the `TMB::tmbprofile()` route for already-validated
direct profile targets. Instead of aborting the whole interval request, it
returns the requested parameter row with missing endpoints,
`conf.status = "profile_failed"`, `profile.boundary = NA`, and the failure
message in `profile.message`. Boundary flags remain reserved for diagnostics
that actually identify a non-finite interval or a lower SD/correlation
boundary.

The `tmbprofile` and endpoint routes also translate non-finite interval
diagnostics into `profile_failed`, so a profile row with `NA` endpoints is not
reported as a successful profile.

The new regression fixture fits a tiny bivariate q=4 phylogenetic
location-scale model with matching labelled
`phylo(1 | p | species, tree = tree)` terms in `mu1`, `mu2`, `sigma1`, and
`sigma2`. It verifies that the sigma-side phylogenetic SDs are direct native
TMB profile targets through `log_sd_phylo` indices 3 and 4, and that the six
q=4 phylogenetic correlations remain derived, unavailable profile targets.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `man/confint.drmTMB.Rd`
- `NEWS.md`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-targets.R
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::load_all('.', quiet = TRUE); testthat::test_file('tests/testthat/test-profile-targets.R', desc = 'confint reports numeric profile failures by row')"
Rscript --vanilla -e "devtools::load_all('.', quiet = TRUE); testthat::test_file('tests/testthat/test-profile-targets.R', desc = 'profile target inventory covers bivariate q4 phylo sigma axes')"
Rscript --vanilla -e "devtools::load_all('.', quiet = TRUE); testthat::test_file('tests/testthat/test-profile-targets.R', desc = 'endpoint engine keeps unsupported targets on current profile paths'); testthat::test_file('tests/testthat/test-profile-targets.R', desc = 'profile confidence intervals reject unsupported targets clearly')"
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
```

## Results

- The explicit `profile_failed` row unit test passed.
- The bivariate q=4 phylogenetic sigma-axis target inventory test passed with
  the expected tiny-fit `sdreport()` warning suppressed in the test fixture.
- The two compatibility tests around endpoint unsupported targets and profile
  validation passed after keeping deliberate endpoint validation errors fatal
  while converting valid profile-evaluation failures into status rows.
- The full `profile-targets` test file passed.
- `git diff --check` reported no whitespace problems.
- The generated documentation change was restricted back to
  `man/confint.drmTMB.Rd` after removing unrelated roxygen-version churn.

## Issue #551 Gate Status

| Gate | Status in this slice |
| --- | --- |
| q4 phylogenetic sigma SD target inventory | Covered by focused regression test. |
| q4 sigma `confint()` success/failure under `pdHess = FALSE` | Deferred to the next #551 slice. |
| Boundary or failed-profile row status | Covered for generic direct numeric failures; q4-specific profile behavior is deferred. |
| `keep_tmb_object = FALSE` profile error coverage | Existing profile-target tests cover missing retained TMB object; no new q4-specific case here. |
| User-facing target-selection note for Ayumi | Deferred until CI is green and q4 sigma `confint()` behavior is tested. |

## Boundaries

This slice does not implement native-TMB REML for bivariate q=4
location-scale phylogenetic models. It also does not make q=4 phylogenetic
correlations profile-ready, speed up the 10k-tip Julia route, or validate
profile coverage. The immediate fallback remains native-TMB ML profile status
for direct sigma-side phylogenetic SD targets.
