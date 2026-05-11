# After Task: Profile SD And Correlation Intervals

## Goal

Extend public profile-likelihood confidence intervals beyond direct fixed-effect
coefficients to the first ordinary random-effect scale and covariance targets:
`sd(group)` and group-level correlation terms from fitted random-effect blocks.

## Implemented

- `confint.drmTMB(method = "profile")` now accepts profile-ready
  random-effect SD targets such as `sd:mu:(1 + x | p | ID):(Intercept)`.
- The same profile path now accepts ordinary random-effect correlation targets
  such as `cor:mu:cor((Intercept),x | p | ID)`.
- SD profile intervals are returned on the SD scale by transforming
  `log_sd_*` intervals with `exp()`.
- Random-effect correlation profile intervals are returned on the correlation
  scale by transforming `eta_cor_mu` intervals with `0.999999 * tanh()`,
  matching the guard in `src/drmTMB.cpp`.
- Unsupported profile targets still fail before expensive profiling starts.
  This keeps transformed ordinal cutpoints, modelled group-SD rows, and derived
  summaries out of the public promise until their algebra and tests are ready.
- `NEWS.md`, `ROADMAP.md`, `docs/design/12-profile-likelihood-cis.md`, and the
  generated `man/confint.drmTMB.Rd` now describe the same partial Phase 6
  boundary.

## Mathematical Contract

For an ordinary random-effect SD target, the profiled scalar is the relevant
optimized `log_sd_*` TMB parameter. If `TMB::tmbprofile()` returns a link-scale
interval `[L, U]`, `confint.drmTMB()` reports `[exp(L), exp(U)]`.

For an ordinary random-effect correlation target, the profiled scalar is the
relevant optimized `eta_cor_mu` parameter. If `TMB::tmbprofile()` returns
`[L, U]`, `confint.drmTMB()` reports
`[0.999999 * tanh(L), 0.999999 * tanh(U)]`. This is a group-level random-effect
correlation interval, not a residual `rho12` coefficient interval.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `man/confint.drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-profile-sd-correlation-intervals.md`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE)"`
- `git diff --check`
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`
- `rg -n "Only fixed-effect profile targets|fixed-effect targets only|profile.*SD.*planned|profile.*correlation.*planned" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`
- `rg -n "O.Dea/Nakagawa|O.Dea-style" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`

The focused profile-target suite passed with 80 expectations, no failures, no
warnings, and no skips after switching to a stable grouped-data fixture. The
full package test suite passed with 1560 expectations, no failures, no
warnings, and no skips. `devtools::check(document = FALSE, manual = FALSE)`
passed with 0 errors, 0 warnings, and 0 notes. Pkgdown rebuilt and
`pkgdown::check_pkgdown()` found no problems.

## Tests Of The Tests

The new positive-path test compares the public `confint()` output for one SD
target and one correlation target against manual `TMB::tmbprofile()` calls with
the matching one-hot linear combinations over `fit$opt$par`. The test then
checks the response-scale transformations exactly: `exp()` for SD and
`0.999999 * tanh()` for group-level correlation.

The unsupported-target test now uses an ordinal cutpoint target, so random-effect
SD targets are no longer used as a negative example after becoming supported.

## Consistency Audit

- Public documentation now says profile intervals support explicit direct
  fixed-effect, ordinary random-effect SD, and ordinary random-effect
  correlation targets.
- `ROADMAP.md` still marks Phase 6 as partly implemented because residual
  `rho12` link-scale profile intervals, ordinal cutpoints, modelled group-SD
  rows, and derived summaries remain unfinished.
- Stale wording scans found no remaining claims that only fixed-effect profile
  targets are supported in the touched files or generated pkgdown pages.
- The reader-facing shorthand scan found no prohibited paper-name shorthand in
  the touched files or generated pages.

## What Did Not Go Smoothly

The first small random-effect fixture was too weak for stable profile
interpolation. `confint.tmbprofile()` did not have enough usable interpolation
points and failed after warning about collapsed unique `x` values. The test now
uses `n_id = 24`, `n_each = 6`, and seed `20260598`, which kept the target suite
fast while giving the profile enough curvature.

## Team Learning

Fisher's lesson is that profile tests need a deliberately stable likelihood
shape, not just a fast toy fit. Rose's lesson is that negative tests must be
revisited whenever a previously unsupported target becomes supported. Pat's
lesson is that the help page must state the reported scale directly: SD
intervals are on the SD scale, and correlation intervals are on the correlation
scale.

## Known Limitations

- No residual `rho12` profile interval has been tested or exposed beyond
  fixed-effect coefficient targets on the link scale.
- No transformed ordinal cutpoint intervals are implemented.
- No modelled group-SD, ICC, repeatability, phylogenetic signal, scale-variance,
  or complete double-hierarchical derived-summary intervals are implemented.
- Phylogenetic SD targets may share the same direct `log_sd_*` pattern, but they
  are not claimed here because this slice did not add a focused phylogenetic
  profile test.

## Next Actions

1. Add residual `rho12` target tests that make the link-scale coefficient versus
   response-scale residual correlation distinction explicit.
2. Add a listed-target helper or documented target inventory so users can see
   which `parm` values are profile-ready before running an expensive profile.
3. Design derived profile intervals for variance-facing summaries only after
   the direct-parameter paths are stable and named extractors exist.
