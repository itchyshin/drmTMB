# Check log: Julia cross-family Gaussian link guard (#1750)

**Date:** 2026-11-19
**Branch:** `cursor/fix-1750-xfam-gaussian-link-726d`

## Change

`drm_julia_xfam_family_tag()` in `R/julia-bridge.R` returned `"gaussian"`
for every `gaussian()` family. DRM.jl's cross-family Gaussian axis assumes an
identity mean link, so `c(gaussian(link = "log"), poisson())` was sent to
Julia as an identity-link Gaussian. The tag now returns `NULL` for a
non-identity Gaussian link, the same rule the Poisson, binomial, NB2, beta and
Gamma axes already follow. The pair is then not a cross-family pair and
`engine = "julia"` aborts in R with the existing mixed-response message.

## Failure on main

`R/julia-bridge.R` at `74007c485`, no Julia installed.
`tests/testthat/test-fix-1750-xfam-gaussian-link.R`: 4 failures and 1 error.
The tag was `"gaussian"` for `gaussian(link = "log")` and
`gaussian(link = "inverse")`, `drm_julia_is_cross_family()` was `TRUE` for
those pairs, and `drmTMB(..., engine = "julia")` reached
`drm_julia_call_xfam()` (it stopped only because JuliaCall was absent).

## Verification with the fix

R 4.6.2, TMB 1.9.25, `pkgload::load_all()`.

| File | Result |
| --- | --- |
| `test-fix-1750-xfam-gaussian-link.R` | 7 pass |
| `test-xfam-bridge.R` | 54 pass, 4 live-Julia skips (no DRM.jl) |
| `test-env-skip-census.R` | 5 pass |

## Claim boundary

No live Julia fit was run. A live-Julia variant of the test was not added
because a new skip site would need an `env-skip-census.tsv` refresh.
