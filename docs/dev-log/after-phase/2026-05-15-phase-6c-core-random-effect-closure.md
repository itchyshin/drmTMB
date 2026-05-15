# After Phase: Phase 6c Core Random-Effect Closure

## Goal

Close the Phase 6c core before moving to Phases 10 and later. This closure is
for the ordinary grouped random-effect foundation: random intercepts, one
ordinary random slope, ordinary intercept-slope correlation, residual-scale
random effects, direct `sd(group)` models, and the output/status contract.

## Scope Boundary

This closure does not fit structured phylogenetic or spatial random slopes.
`phylo(1 + x | species, tree = tree)` and
`spatial(1 + x | site, coords = coords)` remain planned and should be handled
inside the relevant Phase 12 and Phase 10 work, respectively. The Phase 6c
core supplies the ordinary baseline and names the implementation contract those
future slices must satisfy.

## Standing Review Closure

- Ada: the section is ready to hand forward because the ordinary mixed-model
  baseline now has a source map, roadmap status, tests, and local docs gate.
- Gauss: fitted claims are limited to existing Gaussian ordinary grouped
  paths; structured slopes are not described as implemented.
- Noether: the equation, syntax, extractor, `corpairs()`, and
  `profile_targets()` path is explicit for the ordinary one-slope core.
- Darwin: the thermal reaction-norm example gives a biological interpretation
  for baseline differences, plasticity differences, and intercept-slope
  correlation.
- Pat: the model map tells applied users where to read random-intercept SDs,
  random-slope SDs, residual `sigma`, `sd(group)`, and residual `rho12`.
- Grace: focused random-effect, profile-target, and diagnostic tests passed;
  pkgdown builds when Pandoc is on `PATH`, and `pkgdown::check_pkgdown()` is
  clean.
- Rose: the source and rendered scans found no new overclaim that structured
  slopes, bivariate slopes, or random effects in `rho12` are fitted.

## What Changed

- Phase 6c Slices 69-70 are done for the ordinary core.
- Slice 71 and Slice 72 are closed as design handoffs to Phases 12 and 10,
  not as fitted implementations.
- Slice 73 is done for ordinary diagnostics and direct profile-target status.
- Slice 74 is done as an advanced slope-correlation gate.
- Slice 75 is done for the bounded ordinary reaction-norm example.
- Slice 76 is done locally with focused tests, pkgdown build/check, scans,
  check-log entry, and this after-phase note.

## Validation

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/33-phase-6c-core-random-effects.md docs/dev-log/after-phase/2026-05-15-phase-6c-core-random-effect-closure.md vignettes/location-scale.Rmd`:
  passed.
- `/usr/local/bin/Rscript -e 'devtools::test(filter = "gaussian-random-intercepts|profile-targets|check-drm", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::build_site()'`:
  passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `rg -n 'Phase 6c closes|Closure boundary|Design handoff done|thermal reaction-norm|mean-slope|Move to Phases 10|Done locally for the Phase 6c core|structured-slope implementation problem' ROADMAP.md docs/design/33-phase-6c-core-random-effects.md docs/dev-log/after-phase/2026-05-15-phase-6c-core-random-effect-closure.md vignettes/location-scale.Rmd pkgdown-site/ROADMAP.html pkgdown-site/articles/location-scale.html --glob '!pkgdown-site/search.json'`:
  confirmed source and rendered closure wording.
- `rg -n 'phylo\\(1 \\+ x.*Implemented|spatial\\(1 \\+ x.*Implemented|structured random slopes.*implemented|bivariate random slopes.*implemented|random effects in .*rho12.*implemented|rho12 random effects.*Implemented|slope-specific .*sd\\(.*Implemented|full structured.*done|all Phase 6c.*implemented' ROADMAP.md docs/design vignettes README.md NEWS.md --glob '!docs/dev-log/**'`:
  found one valid guardrail phrase saying bivariate random slopes are future.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes in 2m 23.2s.

## Known Limitations

- GitHub Actions remains a PR-side gate.
- Full structured slope fitting is future work.
- Final structured-slope tutorials should wait until the fitted Phase 10-13
  surfaces settle.

## Next Phase

Move to Phases 10 and later with this boundary:

1. Phase 10 should treat `spatial(1 + x | site, coords = coords)` as a
   structured-slope implementation problem, not tutorial polish.
2. Phase 11 can build on the ordinary `corpairs()` and coefficient-column
   contract when adding bivariate covariance rows.
3. Phase 12 should reuse the same one-slope output and diagnostic contract for
   phylogenetic slopes once recovery evidence exists.
4. Phase 13 should treat random-effect SDs and correlations as derived-summary
   inputs only when the corresponding fitted targets and interval statuses are
   explicit.
