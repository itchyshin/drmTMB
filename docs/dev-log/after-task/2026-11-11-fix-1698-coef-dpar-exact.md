# After Task: exact dpar names for native coef()/fixef() (#1698)

## Goal

Stop `coef()` and `fixef()` from partial-matching `dpar` on native `drmTMB`
fits, and give unknown names the same exact-match abort as `predict()`, with a
"Did you mean" line that does not pick the wrong name.

## Implemented

`drm_resolve_fitted_dpar_name()` in `R/utils.R` requires an exact fitted name.
Suggestions list every case-sensitive prefix; if there is no prefix, they list
every case-insensitive `adist` tie within cutoff 2; if nothing is close, the
error has no suggestion. The abort has class `drmTMB_unknown_dpar` and takes
`call = parent.frame()` so the printed error names `coef()` or `predict()`.
`R/methods.R` still only swaps `match.arg()` for this helper at `coef.drmTMB()`,
`predict.drmTMB()`, and `drm_fixed_effect_basis()`.

## Mathematical Contract

No likelihood or formula change. The public `dpar` selector is an exact string
match against `names(fit$coefficients)`.

## Files Changed

- `R/utils.R`
- `R/methods.R` (original slice; not edited in the review follow-up)
- `tests/testthat/test-fix-1698-coef-dpar-exact.R`
- `NEWS.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.d/2026-11-11-fix-1698-coef-dpar-exact.md`

## Checks Run

R 4.6.2, `pkgload::load_all(compile = FALSE)` after an O0 compile of the
unchanged C++ sources.

- Branch: `test-fix-1698-coef-dpar-exact.R` 38 pass, 0 fail; `test-sd-selector-contract.R` 29 pass, 0 fail.
- `main` `R/utils.R` + `R/methods.R` with the new tests: 8 pass, 18 fail, 3 error.

## Tests Of The Tests

The new file was run against `main`'s `coef()` / `fixef()` / `predict()` /
`drm_fixed_effect_basis()` sources. `dpar = "s"` still returns sigma, so every
classed-error and "Did you mean" assertion failed. `drm_suggest_closest_name()`
does not exist on `main`, so the helper assertions failed. Exact `dpar = "sigma"`
extracts still passed.

## Consistency Audit

`rg` `match.arg\\(dpar` in `R/` still finds Julia-bridge and internal sites that
this slice does not change: `R/julia-bridge.R` 8938, 11385, 13445, 13574;
`R/julia-joint-methods.R` 464; `R/methods.R` 7261, 7319. NEWS and the selector
section of `docs/design/18-random-effect-scale-models.md` now say native fits
only. Status-inventory files other than NEWS were not edited.

## GitHub Issue Maintenance

Issue #1698 stays open on draft PR #1721. No extra issue comment.

## What Did Not Go Smoothly

The first suggestion helper used `which.min(adist())` with no prefix pass and no
cutoff, so `dpar = "s"` suggested `mu`, `SIGMA` and `zzz` also suggested `mu`,
and `mu` versus `mu1`/`mu2` suggested only `mu1`. The review follow-up keeps
that logic in `R/utils.R` so `R/methods.R` does not change again.

## Team Learning

A "closest name" helper needs a prefix pass and a distance cutoff before
`which.min()`. Otherwise the suggestion contradicts the available-names list.

## Known Limitations

Julia-bridge `coef()` / `predict()` methods still `match.arg()` `dpar`.
`R/methods.R` is on the C17/C14 source-file watchlist; a tolerance-0 ledger
recertify is pending on the Mac and was not done here.

## Next Actions

Recertify the C17/C14 ledger on the Mac at tolerance 0 after this PR's
`R/methods.R` blob is accepted. Keep the PR as a draft until that recertify.
