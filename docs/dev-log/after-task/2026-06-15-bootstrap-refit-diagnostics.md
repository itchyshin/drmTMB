# After Task: Bootstrap Refit Diagnostics

## Goal

Make `confint(method = "bootstrap")` failures inspectable at the refit-by-target
grain before trying another Ayumi q4 native-bootstrap or reduced-size bootstrap
run.

## Implemented

Bootstrap interval results now carry a `"bootstrap.diagnostics"` attribute with
one row per bootstrap refit and requested target. The visible interval table
stays target-grain; the diagnostics ledger records refit convergence, target
availability, finite estimate flags, row status, refit message, seed/backend
and worker provenance, refit-control flags, per-refit target counts, draw value,
and whether each draw entered the percentile interval. The Ayumi q4 harness
writes the same ledger to `bootstrap-diagnostics.csv`.

## Mathematical Contract

No interval algorithm changed. Percentile bootstrap endpoints still use finite
target draws from successful refits on the same scale as before. The new ledger
only records why a draw was or was not usable.

## Files Changed

- `R/profile.R`
- `tools/ayumi-q4-status-harness.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `vignettes/model-workflow.Rmd`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-bootstrap-refit-diagnostics.md`

## Checks Run

- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-profile-targets.R")'`
  passed with 797 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript --vanilla -e 'devtools::test(filter = "profile-targets")'`
  passed with 797 expectations, 0 failures, 0 warnings, and 0 skips in
  59.3 s.
- Tiny Ayumi native TMB ML bootstrap diagnostics smoke:
  `DRMTMB_AYUMI_Q4_SIZES=30`, `DRMTMB_AYUMI_Q4_ENGINES=tmb`,
  `DRMTMB_AYUMI_Q4_REML=false`, `DRMTMB_AYUMI_Q4_BOOTSTRAP=2`,
  `DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=first_sigma`, source/refit
  `optimizer_preset = "careful"`, output
  `/tmp/drmtmb-ayumi-evidence/native-tmb-30-ml-bootstrap-diagnostics-b3e3fc4a-152933`.
  The run wrote `bootstrap-diagnostics.csv` with two diagnostic rows for
  `sd:mu:sigma1:phylo(1 | p | species)`, both `refit_status = "ok"`,
  `refit_converged = TRUE`, `target_available = TRUE`, and
  `draw_used = TRUE`.

## Tests Of The Tests

The focused test now asserts the exact diagnostics columns and provenance values
for successful direct-target bootstrap intervals. A separate mocked-refit test
forces every bootstrap refit to error and checks that the ledger keeps
`refit_error`, the repeated error message, missing convergence code, missing
target availability, and false finite-estimate flags.

## Consistency Audit

Rose boundary: this is a diagnostic ledger, not a new bootstrap capability
claim. I checked bootstrap wording in `NEWS.md`, `ROADMAP.md`,
`vignettes/model-workflow.Rmd`, `docs/design/12-profile-likelihood-cis.md`,
`R/profile.R`, `tools/ayumi-q4-status-harness.R`, and the profile-target tests
with:

```sh
rg -n "bootstrap\\.diagnostics|bootstrap_unavailable|bootstrap.failed|bootstrap refit|profile_failed|Ayumi" README.md ROADMAP.md NEWS.md docs vignettes R tests tools -g '!docs/dev-log/after-task/*.md'
```

## GitHub Issue Maintenance

This belongs to `drmTMB#555`, the Ayumi 10k q4 Gaussian REML speed and
bridge-status harness. The issue remains open because the diagnostics ledger
does not yet provide a usable Ayumi-scale native TMB bootstrap fallback or a
full bivariate q4 REML fallback.

## What Did Not Go Smoothly

The previous bootstrap evidence had aggregate `bootstrap.failed` counts but no
row-level reason for failure. That made the 100-tip native smokes hard to act
on: we knew both refits failed, but not whether the next slice should focus on
source convergence, refit convergence, target extraction, or non-finite draws.

## Team Learning

Fisher and Emmy agreed on the same shape: keep diagnostics off the printed
interval table, record per-refit evidence as an attribute, and do not imply
coverage or Ayumi-scale success from tiny bootstrap pilots.

## Known Limitations

- No native TMB REML support is added for the bivariate q4 sigma-phylo cell.
- No retry-on-nonconvergence policy is added to bootstrap refits yet.
- The ledger records optimizer messages and target availability; it does not
  prove interval coverage or fix weak-Hessian point fits.

## Next Actions

Run the next larger Ayumi q4 native bootstrap subset with this branch and
inspect `bootstrap-diagnostics.csv`. If the ledger shows mostly nonconverged
refits, the next R-side slice is an explicit refit-retry policy; if it shows
target extraction or non-finite draw problems, fix those before increasing `R`.
