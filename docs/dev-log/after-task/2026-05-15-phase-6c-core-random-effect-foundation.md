# After Task: Phase 6c Core Random-Effect Foundation

## Goal

Preserve the Phase 6b tutorial scaffold, then start Phase 6c with the ordinary
grouped random-effect foundation before moving into Phases 10-13. The core
target was random intercepts, the ordinary one-slope baseline, extractor names,
`corpairs()` rows, and profile/diagnostic status.

## Implemented

- Committed the Phase 6b Slices 62-68 tutorial scaffold as
  `61e9781 Preserve Phase 6b tutorial scaffold`.
- Added `docs/design/33-phase-6c-core-random-effects.md` as the Phase 6c core
  ledger for ordinary grouped random intercepts, random slopes, residual-scale
  random effects, direct `sd(group)` models, and deferred structured-slope
  surfaces.
- Updated `docs/design/04-random-effects.md` and
  `docs/design/17-correlated-random-effect-blocks.md` to point to the Phase 6c
  core source map.
- Updated `ROADMAP.md` so Slices 69-70 are marked done for the ordinary core
  and Slice 73 is marked done for ordinary diagnostics/profile-target status,
  with phylogenetic and spatial slopes left planned.
- Updated the model map and location-scale tutorial so users can read ordinary
  random-intercept, random-slope, residual-scale, `sd(group)`, and `rho12`
  layers as separate model quantities.
- Added a focused regression test that labelled `(1 + x | p | ID)` blocks
  produce a `corpairs()` `mean-slope` row with the expected group, block,
  coefficient, and alias-filter behavior.

## Mathematical Contract

The ordinary Phase 6c core is:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j
[b_0j, b_1j]' = diag(sd0, sd1) L_corr [u_0j, u_1j]'
```

The random-intercept SD, random-slope SD, and intercept-slope correlation are
group-level quantities. They are not residual `sigma` and not residual
`rho12`. Residual-scale random effects enter `log(sigma)`, and `sd(group)`
models the standard deviation of a `mu` random intercept.

## Files Changed

- `ROADMAP.md`
- `docs/design/04-random-effects.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-6c-core-random-effect-foundation.md`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `vignettes/location-scale.Rmd`
- `vignettes/model-map.Rmd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/33-phase-6c-core-random-effects.md docs/dev-log/after-task/2026-05-15-phase-6c-core-random-effect-foundation.md tests/testthat/test-gaussian-random-intercepts.R vignettes/location-scale.Rmd vignettes/model-map.Rmd`:
  passed.
- `/usr/local/bin/Rscript -e 'devtools::test(filter = "gaussian-random-intercepts|profile-targets|check-drm", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.
- `/usr/local/bin/Rscript -e 'pkgdown::build_site()'`: failed once because
  Pandoc was not on the shell `PATH`.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::build_site()'`:
  passed after making `/opt/homebrew/bin/pandoc` visible.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `rg -n 'Phase 6c core|33-phase-6c|mean-slope|location-slope|groups differ in baseline|groups differ in the .x. slope|ordinary grouped core|Done for the ordinary core|random-effect foundation' ROADMAP.md docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/33-phase-6c-core-random-effects.md docs/dev-log/after-task/2026-05-15-phase-6c-core-random-effect-foundation.md vignettes/location-scale.Rmd vignettes/model-map.Rmd pkgdown-site/ROADMAP.html pkgdown-site/articles/location-scale.html pkgdown-site/articles/model-map.html --glob '!pkgdown-site/search.json'`:
  confirmed source and rendered Phase 6c-core wording.
- `rg -n 'phylo\\(1 \\+ x.*Implemented|spatial\\(1 \\+ x.*Implemented|structured random slopes.*implemented|bivariate random slopes.*implemented|random effects in .*rho12.*implemented|rho12 random effects.*Implemented|slope-specific .*sd\\(.*Implemented' ROADMAP.md docs/design vignettes README.md NEWS.md --glob '!docs/dev-log/**'`:
  found one valid guardrail phrase in `docs/design/01-formula-grammar.md`
  saying bivariate random slopes are future.

## Tests Of The Tests

The new test would fail if `corpairs()` dropped the labelled ordinary
intercept-slope row, lost the `p` block label, changed the coefficient columns,
or stopped accepting `class = "location-slope"` as an alias for the fitted
`mean-slope` row.

## Consistency Audit

The update keeps random intercepts as the baseline for later bivariate,
phylogenetic, spatial, and derived-inference phases. It does not claim
structured random slopes are fitted. `phylo(1 + x | species, tree = tree)`,
`spatial(1 + x | site, coords = coords)`, bivariate random slopes,
slope-specific `sd()` targets, and random effects in `rho12` remain planned or
unsupported.

## Known Limitations

- This task does not implement new likelihood behavior.
- Full Phase 6c closure still needs the final gate, GitHub Actions evidence,
  and any later structured-slope design/fitting slices that are deliberately
  interleaved with Phases 10 and 12.
- The final biological tutorial examples for structured slopes should wait
  until the corresponding model surfaces are stable.
