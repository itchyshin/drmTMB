# After-task: R-bridge admissions for Poisson relmat slope SD and NB2 animal slope SD

## Inconsistency

DRM.jl f0566fb5b (origin/codex/general-sd-regression) implements two routes
that drmTMB's R gates still refused for `engine = "julia"`: Poisson `relmat(0 + x | g)` slope-only
SD (bridge payload widened from Binomial) and NB2 `animal(0 + x | g)` slope-only
SD (raw A). Native TMB fits both.

## What was done

- `R/julia-bridge.R`
  - `drm_julia_poisson_relmat_sd_slope_route_admitted()`: the Binomial relmat
    SD shape restricted to a slope-only term. Wired into the marker-slope
    refusal, the SD label-key branch, the `resd` label bypass, and
    `drm_julia_structured_payload()` (coefficient and marker-type checks, family
    guard: the payload rechecks `family_type == "poisson"`).
  - `drm_julia_nbinom2_animal_sd_slope_route_admitted()`: the Poisson animal
    slope shape with an optional explicit `sigma ~ 1` entry removed first. Wired
    into the marker-slope refusal and the payload. Only the `A` form is admitted;
    `Ainv` and `pedigree` forms stay refused for NB2 by the existing Ainv gate.
  - Poisson relmat slope payload refuses a non-unit-diagonal K (see Findings).
- `tests/testthat/test-julia-b18-relmat-nb2-slope-sd-bridge.R`: static gate tests
  (admit, wrong shape, wrong family, Ainv, non-unit K) plus one live bridge test
  per route against native TMB.
- No R test encoded NB2 normalisation (searched `tests/testthat` for nbinom2 plus
  normali[sz]e; none concerned the animal route), so none changed.

## Results

Tolerances fixed in advance: every coefficient block within 1e-3 absolute,
logLik within 1e-2 absolute, native TMB (`se = FALSE`) on the same fixture.
Run on the Mac, Julia 1.10.0, DRM.jl at `general-sd-julia` worktree, 2 threads.

| Route | Fixture | max coef diff (blocks) | logLik diff | Verdict |
|---|---|---|---|---|
| Poisson relmat slope SD | n_id 64 x 24 obs, K = 0.4^|i-j| (unit diag), seed 20261101 | mu 6.9e-09, sd_relmat 1.5e-08 | 1.5e-05 (-2264.9054 both) | within tolerance |
| NB2 animal slope SD | pedigree A for 64 offspring, rescaled D A D with d in [0.8, 1.5] (non-unit diag), sigma ~ 1, seed 20261101 | mu 1.0e-08, sigma 7.9e-08, sd_animal 1.1e-07 | 1.9e-06 (-2731.1966 both) | within tolerance |

Neighbouring tests re-run clean: Poisson animal slope parity, Binomial relmat
slope bridge, admission census, admission docs, phylo/slope nongaussian.

## Findings while fixing

- **Poisson relmat with non-unit-diagonal K disagrees across engines.** DRM.jl
  rescales a relmat K to a correlation matrix; native uses K as given. With
  unit-diagonal K the engines agree (above). With K = outer(s, s) * corr,
  s in [0.8, 1.4], the same data gave native logLik -2268.343 vs Julia -2271.155
  (gap 2.81), mu slope 0.152 vs 0.096, sd z-coefficient 0.421 vs 0.412, sd
  intercept -0.474 vs -0.334. This is a different model, not an optimiser gap,
  because the group SD regression does not absorb group-specific K scaling.
  The R gate therefore refuses non-unit-diagonal K for this route.
- **The Binomial relmat slope route probably has the same issue.** Its existing
  test compares at tolerance 0.1 on a non-unit-diagonal K, which would hide it.
  Not checked here; not changed.
- NB2 animal with raw non-unit A agrees at about 1e-7, consistent with the Julia
  raw-A change (177af5353).
- Julia report says the NB2 `relmat` K is still correlation-normalised; the same
  mismatch is expected there and NB2 relmat is not admitted here.

## Not covered

- One fixture per route, one seed; no coverage, SE, profile, or bootstrap claim.
- NB2 animal slope has no bootstrap or marginal simulator on the Julia side;
  `simulate()` on this route was not exercised.
- NB2 `Ainv` and pedigree forms, NB2 relmat, Poisson relmat intercept, and any
  `sigma` model beyond `~ 1` are not admitted.
- Docs (julia-engine vignette, capability/parity registry, DRM.jl capabilities.md)
  were not updated; the docs lane should add both routes and the unit-diagonal
  condition.
