# After Task: Poisson animal-slope SD bridge parity

## 1. Goal

Verify one same-data Poisson animal-slope predictor-dependent SD fit through
the R-to-Julia bridge and record its exact boundary.

## 2. Implemented

The Julia bridge admits the complete-data, non-inflated Poisson route with one
animal slope-only coefficient, `animal(0 + x | id, A = A)`, and
`sd(id, level = "animal") ~ z`. Structural guards reject a mismatched group,
an extra independent random effect, and an intercept-plus-slope animal block.
The bridge test compares native TMB and Julia coefficients, log likelihood,
and group-named SD predictions on the same synthetic data.

## 3. Mathematical Contract

For group-level predictor row `w_g`, the conditional SD of the animal-slope
loading is `sd(b_g) = exp(w_g alpha)`. The parity fixture uses a supplied
unit-diagonal covariance with shuffled labels, so this comparison avoids the
known TMB-versus-Julia difference for non-unit-diagonal covariance scaling.
The target is the coefficient SD of the single random slope; the residual and
observation scales are unchanged.

## 3a. Decisions and Rejected Alternatives

The route is limited to one animal coefficient because the tested Julia bridge
exposes no verified predictor-dependent SD mapping for the intercept-plus-slope
block. The supplied covariance is kept at unit diagonal in the parity fixture;
changing or normalizing the user's covariance would change the comparison
target and was not introduced.

## 4. Files Touched

- `R/julia-bridge.R` adds the narrow Poisson animal-slope admission and guard.
- `tests/testthat/test-julia-poisson-animal-slope-sd-parity.R` adds structural
  admission controls and the live cross-engine fixture.
- `vignettes/julia-engine.Rmd`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`,
  `docs/dev-log/known-limitations.md`, and `docs/design/capability-status.md`
  document the candidate route and its limitations.
- `.unlazy/general-sd-regression/GATES.md`, `docs/dev-log/check-log.md`, and
  this report record partial evidence only.

## 5. Checks Run

- Exact live test:
  `DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-poisson-animal-slope-sd-parity")'`
- Result: 17 passed, 0 failed, 0 warnings, 0 skipped; one live Julia bridge test
  ran in 30.3 seconds.
- On the fixed fixture, the observed maximum SD-coefficient difference was
  `4.98e-8`, maximum group-SD difference was `7.43e-8`, and Julia minus TMB
  log likelihood was `-2.64e-5`. The fitted SD slope was `0.4497` against truth
  `0.5`. Assertions now require coefficient and group-SD differences below
  `1e-4`, log-likelihood difference within `1e-3`, and slope error below `0.1`.
- Adjacent filter:
  `devtools::test(filter = "poisson-animal-(sd-regression|slope-sd-regression)|julia-poisson-animal-slope-sd-parity")`
  passed 41 checks with no failures, warnings, or skips. This includes native
  animal intercept and slope regression plus the live bridge comparison.
- The same command first failed before model fitting because sandbox access
  denied JuliaCall's compiled-module cache pidfile. With authorized cache
  access, the exact test passed.
- The Julia vignette rendered from this candidate to
  `/private/tmp/julia-engine.html`; only the existing Pandoc `--mathjax`
  deprecation warning was reported. `pkgdown::check_pkgdown()` passed with no
  problems; existing Pandoc `--mathml` warnings remain.
- GitHub open-issue search for `Poisson animal SD` returned no matches.
- The task-specific status scan covered `README.md`, roadmap, NEWS, known
  limitations, formula grammar, the Julia guide, and `_pkgdown.yml`; there is
  no applicable README or navigation entry to add. Exact command:
  `rg -n 'Poisson.*(animal|structured)|animal.*Poisson|sd\\(id.*animal|Poisson animal slope' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd _pkgdown.yml`.
- Scoped `git diff --check` passed. `parse()` passed for the bridge source and
  new test file. The full candidate still needs its own checks.
- Source hashes after this slice: `R/julia-bridge.R`
  `db229b03ace20f3e315803e0b39293b787860841808a2b1e08a477c9b5b7a098`;
  `tests/testthat/test-julia-poisson-animal-slope-sd-parity.R`
  `136a7b62be9f8dc7f333b90c0e63ae80947a60cebe8f3c2fbe5d1b93bd611e3a`.

## 6. Tests of the Tests

The fast test asserts the exact bridge payload and rejects three nearby
unsupported shapes. The live test exercises both `engine = "tmb"` and
`engine = "julia"`, checks convergence and finite coefficients, then compares
named public SD outputs. One seeded fixture supplies no independent likelihood
oracle or interval-calibration evidence.

## 8. Consistency Audit

The R syntax, bridge payload (`sd(id, animal) ~ z`), Poisson family admission,
and public target (`sd_animal(id)`) agree. The capability summary retains
`point-fit-recovery`: this parity fixture does not promote its whole capability
row or prove general engine equivalence. The existing Julia covariance
normalization convention remains unchanged.

## 7a. Issue Ledger

The read-only open-issue search returned no matching Poisson animal-SD issue.
No issue was created, commented on, or closed.

## 9. What Did Not Go Smoothly

The first live rerun could not initialize JuliaCall because the sandbox denied
writing a pidfile under `~/.julia`. The model test passed unchanged after the
required cache access was granted.

## 11. Team Learning

Cross-engine structured parity fixtures should use a unit-diagonal covariance
when the purpose is to compare fitting routes rather than provider scaling.
Keep negative shape controls beside each narrow bridge admission.

## 10. Known Residuals

This evidence covers one complete-data Poisson animal slope-only coefficient,
one supplied unit-diagonal covariance, ML/Laplace fitting, and one synthetic
fixture. It does not establish intercept-plus-slope blocks, other covariance
scales, `Ainv` or pedigree inputs, missing-data support, other families,
profile or bootstrap refit integrity, interval calibration, or broad R/Julia
parity. The 19,118-row required universe remains open; programme gates G3, G4,
G6, G7, and G8 remain partial or unmet. Coverage validation remains deferred.

## Next Actions

Continue source-bound reconciliation against the full required-row inventory.
For this exact route, add save/reload and simulation parity checks only if its
row contract requires them; otherwise move to the next unverified required
family/effect/backend row. Do not promote the public support claim from this
single fixture.

## 12. Cross-Product Coverage

This work covers native R/TMB and Julia bridge point fitting, coefficient
extraction, log likelihood, and group-SD prediction for one Poisson animal
slope-only synthetic fixture with a unit-diagonal supplied covariance. It does NOT cover
other families, ordinary effects, animal intercepts or blocks,
non-unit covariance scaling, `Ainv` or pedigree inputs, simulation, save/reload,
profile/bootstrap refits, interval coverage, or the remaining required rows.
