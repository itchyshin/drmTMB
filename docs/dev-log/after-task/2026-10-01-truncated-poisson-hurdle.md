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

## Review fixes, round 2 (2026-10-02)

- The upper-tail-only quantile helpers from 98c05f6b broke the right-inverse at CDF jump points (`q(F(y))` returned `y + 1` at about a fifth of them), for `truncated_nbinom2()`/hurdle NB2 on main as well as the new family. The zero-truncated CDF is now one helper per family that evaluates the more accurate tail, and the quantile is stepped to the exact generalized inverse of that CDF (hurdle: of `hu + (1 - hu) F(y)`). A test written first, red on 98c05f6b, checks `q(F(y)) == y` and the inverse conditions over mu in `[1e-12, 2500]`, four NB2 scales and two `hu` values.
- `truncated_poisson()` is in `tools/function-cheatsheet-source.Rmd`; the C17/C14 model-15 receipt is re-certified (fingerprint moved only because two model-type names were added inside an authenticated anchor); offset refusals are tested; the unsupported-family message and the `truncated_poisson()` help page are updated.
- Measured results are in the check-log row of the same date.

## Non-claims

No coverage or interval-calibration study was run for this family; the Wald and profile intervals are the generic engine paths. No random-effect, structured, missing-data, `emmeans`, or Julia-bridge support. `fitted()` is the unconditional hurdle mean, as for hurdle NB2.
