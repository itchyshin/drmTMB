# After Task: Cite Julia same-target receipts in `@param engine` (#1569)

Reader: a reviewer of PR #1626, and an applied user reading `?drmTMB`
who needs to know what the 1e-4 / 1e-3 Julia-vs-TMB bar rests on.

## Goal

Point `@param engine` at the existing same-target receipts for
`skew_normal()`, `cumulative_logit()`, `biv_student()`, and
`biv_lognormal()`, instead of a blanket unsourced 1e-4 / 1e-3
sentence. Check whether `test-reml-phylo-location.R:172` also fails
on clean `main` at `f5791d50a`.

## Implemented

`R/drmTMB.R` `@param engine` now says same-target live tests use
coefficients and log-likelihood within 1e-4 and Wald SEs within 1e-3
relative against `engine = "tmb"`, and that measured gaps at DRM.jl
pin 430ef64cc for the four families sit inside those bars. The
sentence names NEWS and the four `tests/testthat/test-julia-family-*.R`
headers. `man/drmTMB.Rd` matches. The admission-doc tests now require
those receipt names and reject the old blanket sentence.

## Mathematical Contract

No likelihood, link, or parameterisation change. The measured gaps
already recorded in NEWS and the family test headers are unchanged:
`skew_normal()` max |d coef| 1.89e-11, |d logLik| 2.16e-12, Wald SE
1.04e-06 relative; `cumulative_logit()` 2.20e-14, 1.13e-11, 5.76e-09;
`biv_student()` 3.771e-07, 2.569e-11, 9.013e-07; `biv_lognormal()`
9.288e-07, logLik -1124.208196846248 vs -1124.208196846242, Wald SE
1.708e-06 relative.

## Files Changed

- `R/drmTMB.R`, `man/drmTMB.Rd`
- `tests/testthat/test-julia-admission-docs.R`
- `NEWS.md`
- C17 receipt
  `docs/dev-log/implementation-recovery/2026-10-25-1569-docs-receipts-c17c2-c14-final-source-compatibility/`
  and the ledger TSV

## Checks Run

- `devtools::test(filter = "julia-admission-docs")`: 26 expectations,
  0 failures.
- `devtools::test(filter = "julia-admission|julia-fe-only")`: 311 pass,
  2 skip (no generic fixture for `biv_student` / `biv_lognormal`),
  1 warning, 0 fail. Live Julia skipped (no DRM.jl here).
- `tools/check-reader-contracts.R`: OK.
- `python3 tools/recertify-c17.py --label 1569-docs-receipts --tolerance 1e-10`:
  worst `|change|` 0.000e+00 on mc-0568, mc-0569, and mc-0576.
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: OK.
- `python3 tools/capability_ledger.py --check`: OK.
- `roxygen2::roxygenise(".", roclets = "rd")`: `man/drmTMB.Rd` kept;
  `DESCRIPTION` RoxygenNote bump and wrap-only drift in
  `man/predict.drmTMB.Rd` and `man/convergence_status.Rd` reverted.
- `test-reml-phylo-location.R` on a clean worktree at `main`
  `f5791d50a2550aebac77ebfc2eb2fd1d713d8b6b`: FAIL 1, PASS 11. Line 172
  expects `fit$opt$convergence` 0 and gets 1. The same failure is
  therefore already on `main`, not introduced by this docs PR.

## Tests Of The Tests

The admission-doc tests fail if NEWS or any of the four
`test-julia-family-*.R` names leave the engine item, and they fail if
the old "Each admitted family has been compared" sentence returns.
They do not call `drmTMB(..., engine = "julia")`.

## Consistency Audit

Recorded searches:

```sh
rg "Each admitted family has been compared" R/drmTMB.R man/drmTMB.Rd
rg "test-julia-family-skew_normal.R|test-julia-family-biv_lognormal.R" man/drmTMB.Rd
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md NEWS.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md vignettes/julia-engine.Rmd
```

Inventory files checked: NEWS documentation bullet, `@param engine`,
`man/drmTMB.Rd`. No `_pkgdown.yml` change.

## GitHub Issue Maintenance

PR #1626 still closes #1569 only. #1475 and #1320 stay open. PRs
#1426 and #1529 were not edited. The reml-phylo failure was not filed
as a new issue from this session.

## What Did Not Go Smoothly

The 1e-4 / 1e-3 bar is the live-test tolerance already written in the
family test headers. The measured gaps sit well inside it. The
follow-up cites those receipts rather than inventing new numbers.

## Team Learning

A hashed-file roxygen comment still needs C17 recertification even
when `source_fingerprint` does not move. Revert unrelated
`document()` wrap drift around open wording issues.

## Known Limitations

Live `engine = "julia"` fits were not rerun. The reml-phylo
convergence failure on `main` is outside this docs change.

## Next Actions

Review PR #1626. Do not merge from this session.
