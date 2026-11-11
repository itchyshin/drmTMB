# After Task: #1716 foreign ziGamma refusal (review revision)

## Goal

Revise draft PR #1723 so the Code Reviewer blockers are gone: keep
`R/drmTMB.R` off the C17 watchlist, regenerate the skip census with the
repository generator, give the refusal its own condition class, and
correct the zero-inflated labels and constructor hints.

## Implemented

`drm_maybe_abort_foreign_inflation_family()` in `R/family.R` wraps
`drm_family_type()` after `R/drmTMB.R` is sourced. Foreign zero-inflated,
hurdle, and truncated stats `family` objects abort with class
`drmTMB_foreign_inflation_family`. `glmmTMB::ziGamma()` still matches as
`family = "Gamma"` plus a `ziformula` initialize hook. `glmmTMB::beta_family()`
and `glmmTMB::lognormal()` are refused as unsupported foreign constructors,
not as zero-inflated families, and the hints name `drmTMB::beta_family()`
and `drmTMB::lognormal()`. The `^zi` name matcher no longer treats `zipf`
as zero-inflated. Documentation lives on `foreign-inflation-families` in
`R/family.R`, with `@seealso` from `beta_family()`, `lognormal()`,
`nbinom2()`, and `truncated_nbinom2()`.

## Mathematical Contract

No likelihood or formula-grammar contract changed. Plain
`Gamma(link = "log")`, `beta_family()`, and `lognormal()` still classify
as `"gamma"`, `"beta"`, and `"lognormal"`.

## Files Changed

- `R/family.R`
- `R/drmTMB.R` (restored to `origin/main`; net PR diff empty)
- `man/drmTMB.Rd` (restored to `origin/main`; net PR diff empty)
- `man/foreign-inflation-families.Rd`
- `man/beta_family.Rd`, `man/lognormal.Rd`, `man/nbinom2.Rd`, `man/truncated_nbinom2.Rd`
- `tests/testthat/test-fix-1716-foreign-zigamma.R`
- `inst/extdata/env-skip-census.tsv` (regenerated)
- `NEWS.md`, `_pkgdown.yml`, `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.d/2026-11-11-fix-1716-foreign-zigamma.md`

## Checks Run

R 4.3.3. Ledger: `python3 tools/capability_ledger.py --check` OK;
`--check-c14-receipt-equivalence` OK with C17 current-source compatibility
PASS. `R/drmTMB.R` SHA `5be5ba5480117fd8527e28b1bba7670d4e09cbca` matches
`origin/main`. Branch `test-fix-1716-foreign-zigamma.R`: 6 tests, 8
passed expectations, 2 skips (`glmmTMB` absent). Same file on
`origin/main` `3f45ade61`: 2 failures, 1 error, 2 skips, 3 passed
expectations; the Gamma-plus-`ziformula` object classifies as `"gamma"`.
`test-env-skip-census.R` 5/0. Related family tests: link-contract 92,
control-family-validators 83, gamma-location-scale 76, all 0 fail.

## Tests Of The Tests

On main, `drm_family_type()` returns `"gamma"` for a stats Gamma family
whose `initialize` mentions `ziformula`. After the wrap it throws
`drmTMB_foreign_inflation_family`. The zipf name test fails on main
because the helper does not exist, and passes after the tightened matcher.

## Consistency Audit

`rg` patterns: `meta_gaussian|tau ~|rho ~` (no new hits in edited files);
`glmmTMB::beta()` (only the test that asserts that label is absent);
`glmmTMB::ziGamma` in NEWS, known-limitations, family docs, and the test.
Status inventory: NEWS and known-limitations updated; README, roadmap, and
formula-grammar unchanged because this is a refusal, not a new family.

## GitHub Issue Maintenance

#1716 stays open on draft PR #1723. No extra issue was opened. The owner
decision to refuse is already recorded on the issue.

## What Did Not Go Smoothly

The first draft edited `R/drmTMB.R` for both the call site and the
`drmTMB()` family paragraph, which tripped the C17 watchlist blob check.
Moving the guard into `R/family.R` as a wrap of `drm_family_type()` keeps
the classifier as the chokepoint without touching the watchlist file.

## Team Learning

A documentation sentence in `R/drmTMB.R` is a watchlist edit. Put
family-refusal docs on a topic in `R/family.R` and link it with `@seealso`
from constructors that are not on the watchlist.

## Known Limitations

This VM does not have `{glmmTMB}` installed, so the live `ziGamma()` /
`beta_family()` / `lognormal()` tests skip here. CI installs Suggests, so
those tests run there. There is still no zero-inflated Gamma family.

## Next Actions

Keep PR #1723 as a draft for re-review. Do not merge until the watchlist,
census, and typed-error assertions are accepted.
