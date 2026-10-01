# After Task: `truncated_poisson()` and hurdle Poisson (`hu`)

Date: 2026-10-01
Lane: Claude, `claude/truncated-poisson-hurdle` (draft PR; never merged by the author, D-164)
Active lenses: Shannon, Gauss, Boole, Noether, Rose (perspectives; no spawned subagents)
Refs: #1267 (twin burn cell 30), DRModels.jl #726 (owner decision 16 (a), 2026-10-01)

Reader: anyone fitting hurdle counts without overdispersion, and the DRModels.jl twin maintainers.

## Goal

drmTMB refused `hu` on `poisson()` while DRModels.jl accepted `Poisson()+hu`. Owner decision 16 (a): drmTMB gains `family = truncated_poisson()` and `hu ~ ...` with it, mirroring `truncated_nbinom2()` + `hu`. `poisson()` + `hu` stays refused, and the message now names `truncated_poisson()`.

## Implemented

Math: zero part Bernoulli(`hu`); positive part `y log(mu) - mu - log(y!) - log(1 - exp(-mu))`, with `log(1 - exp(-mu)) = drm_log1mexp(-mu)`. Written from the math as its own C++ branches (`model_type` 21 plain zero-truncated, 22 hurdle) in `src/drmTMB.cpp`; no code copied from DRModels.jl (license boundary).

R: `truncated_poisson()` constructor; `drm_build_truncated_poisson_spec()` (fixed effects only); start values (moment-corrected truncated start, hurdle start from the zero share); map; coefficient extractor; `predict`/`fitted`/`residuals`/`simulate`/`sigma`/`confint`/`profile`/print label; `drm_dpar_link`; `drm_family_dpq` (`fitted_distribution()`); both random-effect extractor allow-lists.

## NB2-hurdle touchpoints and decisions

See the PR description table. Deliberately not paralleled (refused with a message): random effects and structured terms (`drm_reject_phase1_terms`), offsets, `meta_V()`, `miss_control(response = "include")` and `mi()` (both gated by the existing family allow-lists), `emmeans` preflight (allow-list), `engine = "julia"` (no bridge row; the DRModels.jl bridge needs its own `truncated_poisson` case first), `check_drmTMB()` sigma-based lists (no `sigma`).

## Checks Run

`tests/testthat/test-truncated-poisson-hurdle.R` (new): hand likelihood to 1e-10; `glm` + `VGAM::vglm(pospoisson)` decomposition at n = 600, seed 726; DRModels.jl n = 80 fixture constants to 1e-6; plain truncated vs `VGAM::pospoisson`; methods; distribution functions; refusals. See the PR for the full-suite result.

## Non-claims

No coverage or interval-calibration study was run for this family; the Wald and profile intervals are the generic engine paths. No random-effect, structured, missing-data, `emmeans`, or Julia-bridge support. `fitted()` is the unconditional hurdle mean, as for hurdle NB2.
