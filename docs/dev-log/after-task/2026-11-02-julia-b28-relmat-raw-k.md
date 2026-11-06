# After-task report: batch 28, Julia uses relmat K as supplied (Poisson, NB2, Gamma)

Date: 2026-11-02. Reader: Shinichi, and the next agent on the general-sd-regression lane.

## 1. Goal

Resolve the open parity decision "Julia relmat K: raw or normalised". The decision
is raw. DRModels.jl should use a supplied `relmat()` covariance `K` unchanged on
every Poisson, NB2 and Gamma relmat route (intercept and slope), as native drmTMB
does. `phylo()` keeps the correlation form (native uses `cov2cor(ape::vcv)`), and
`animal()` was already raw.

## 2. Implemented

Julia (DRModels.jl commit `36517ec8c` on `codex/general-sd-regression`, pushed):

- `src/poisson.jl`: the animal/relmat/spatial slope route and the relmat SD
  regression (`_general_cov_setup(K, labels)`) pass `normalize = false`; the
  intercept route passes `normalize = kind === :spatial`, so only the precomputed
  spatial `K` keeps its old rescaling. The default of
  `_fit_poisson_animal_slope_laplace` is now raw.
- `src/negbinomial.jl`: intercept call `normalize = kind === :spatial`; the SD
  route (`_fit_nb2_animal_sd_laplace`) is raw for relmat and animal, intercept
  and slope; default is raw; stale comment fixed.
- `src/gamma.jl`: intercept call `normalize = kind === :spatial`; the structured
  SD route is raw for every provider.
- `src/sparse_laplace_glmm.jl`: the Poisson, NB2 and Gamma `_fit_*_relmat_laplace`
  defaults are now `normalize = false`; docstrings updated. `_general_cov_setup`
  keeps its own default (`true`) because Beta, zero-one-beta and the Gaussian
  location-scale routes still call it without the keyword.
- `src/inference.jl`: the Poisson/NB2 structured SD marginal simulator and the
  Gamma structured SD simulator now draw from the raw `K`, so fit, predict,
  simulate and bootstrap agree on the scale. No other normalising site exists in
  predict or profile code (searched for `d * d'`, `normalize`, `cov2cor`).
- Tests: new `test/test_relmat_raw_k_regression.jl` (dense Laplace oracle,
  non-unit diagonal 0.5 to 2.5, correlated off-diagonals, shuffled rows with
  string labels; Poisson, NB2, Gamma). Four existing tests that asserted the
  normalised-K objective were changed (section 5).

R bridge (this patch):

- `R/julia-bridge.R`: removed the Poisson relmat slope-only refusal of a
  non-unit-diagonal `K`. A search for `unit` and `diagonal` found no other
  K-scale refusal for NB2, Gamma or the relmat intercept routes.
- New `tests/testthat/test-julia-b28-relmat-raw-k-bridge.R`: a non-live block
  pinning that the refusal is gone and that `K` is sent unchanged, plus live
  native-versus-Julia blocks with a non-unit-diagonal `K` for Poisson, NB2 and
  Gamma, `relmat(1 | id)` and `relmat(0 + x | id)` with `sd(id, level = "relmat") ~ z`.
- `tests/testthat/test-julia-b18-relmat-nb2-slope-sd-bridge.R` (not receipted):
  the assertion that a non-unit `K` is refused (`"unit-diagonal"`) is replaced by
  one that the payload is built and `K` is sent unchanged.
- `NEWS.md`, `docs/design/18-random-effect-scale-models.md` (kernel scaling table
  and open parity rows), and this note.

## 3a. Decisions and Rejected Alternatives

- Raw `K`, per the owner's decision. Normalising and refusing were the other two
  options and are rejected.
- The precomputed-`K` spatial intercept for Poisson, NB2 and Gamma keeps its
  rescaling (`normalize = kind === :spatial`). Native spatial uses the fixed
  kernel with diagonal `1 + 1e-6`, so scaling is immaterial there, and the
  instruction was to leave spatial as it is. Changing it is one line per route.
- `_general_cov_setup` keeps its default; the count-family routes pass the
  keyword explicitly. Flipping the helper default would silently change Beta and
  zero-one-beta, which are outside this slice.

## 4. Files Touched

Julia: `src/gamma.jl`, `src/inference.jl`, `src/negbinomial.jl`, `src/poisson.jl`,
`src/sparse_laplace_glmm.jl`; tests `test/test_relmat_raw_k_regression.jl` (new),
`test/test_gamma_relmat_sd_regression.jl`, `test/test_nb2_relmat_sd_regression.jl`,
`test/test_poisson_relmat_sd_regression.jl`,
`test/test_poisson_relmat_slope_sd_regression.jl`.
R (patch): `R/julia-bridge.R`, `NEWS.md`, `docs/design/18-random-effect-scale-models.md`,
`tests/testthat/test-julia-b18-relmat-nb2-slope-sd-bridge.R`,
`tests/testthat/test-julia-b28-relmat-raw-k-bridge.R` (new), this note (new).
Julia docs (`docs/src/families.md`, `capabilities.md`, `tutorials/animal-models.md`)
and `NEWS.md` still say relmat `K` is rescaled; they carry unrelated uncommitted edits
in that worktree and were not committed (wording is in the hand-off report).

## 5. Checks Run

Julia, on Totoro (Julia 1.10.12, `JULIA_NUM_THREADS=1`, one core per process):

| File | Pass | Fail | Error |
|---|---|---|---|
| `test_relmat_raw_k_regression.jl` (new) | 9 | 0 | 0 |
| `test_poisson_relmat_sd_regression.jl` (changed) | 17 | 0 | 0 |
| `test_gamma_relmat_sd_regression.jl` (changed) | 22 | 0 | 0 |
| `test_nb2_relmat_sd_regression.jl` (changed) | 26 | 0 | 0 |
| `test_poisson_relmat_slope_sd_regression.jl` (changed) | 28 | 0 | 0 |
| `test_gamma_structured_slope_sd_regression.jl` | 26 | 0 | 0 |
| `test_nb2_relmat_slope_sd_regression.jl` | 10 | 0 | 0 |
| `test_bridge_poisson_relmat_slope_sd.jl` | 4 | 0 | 0 |
| `test_poisson_structured_sd_offsets.jl` | 20 | 0 | 0 |
| `test_relmat_counts.jl`, `test_relmat_counts_nb2.jl`, `test_relmat_counts_beta.jl` | 19, 27, 18 | 0 | 0 |
| `test_nb2_animal_slope_sd_regression.jl` | 15 | 0 | 0 |
| `test_bootstrap_marginal.jl`, `_formula_structured.jl`, `_nongaussian_structured.jl` | 25, 33, 31 | 0 | 0 |
| `test_bridge_labelled_structured.jl`, `test_structured_plus_ordinary_bar.jl` | 10, 56 | 0 | 0 |
| others (aghq, boundary_polish, finite_hessian_nan, ll_sanity_fuzzer, ordinary_laplace, locscale_bootstrap_simulator, phylo_slope_*, quantile_residuals_re_axis, cox_reid_poisson_ranef, api_stability, pd_guard_structured, heritability) | all pass | 0 | 0 |

Two files could not load for an environment reason unrelated to this change:
`test_cox_reid_poisson_phylo.jl` and `test_temporal_ar1.jl` stop with
`Package StableRNGs not found` (the test-only dependency is missing from the
copied environment). They were not run.

Live native-versus-Julia (Mac, Julia 1.10.0, `NOT_CRAN=true`, tolerances fixed before
running: coefficients 1e-3, logLik 1e-2, native `se = FALSE`):

| Route (non-unit-diagonal K) | max coefficient diff | logLik diff |
|---|---|---|
| Poisson `relmat(1 | id)` | 7.3e-7 (mu) | 1.3e-11 |
| Poisson `relmat(0 + x | id)` with `sd ~ z` | 3.6e-8 | 2.0e-6 |
| NB2 `relmat(1 | id)` | 5.0e-10 (mu), 1.8e-10 (sigma) | 8.4e-11 |
| NB2 `relmat(0 + x | id)` with `sd ~ z` | 1.2e-7 | 1.5e-6 |
| Gamma `relmat(1 | id)` | 2.7e-10 (mu), 4.9e-12 (sigma) | 1.0e-10 |
| Gamma `relmat(0 + x | id)` with `sd ~ z` | 2.3e-8 | 2.3e-6 |

For the intercept routes the random-effect SD is not in the compared coefficient
table; the logLik match to 1e-10 carries it. The final b28 file run had no failures. Existing live bridge files rerun after the
change, one R process at a time, all passing: b18 (Poisson relmat slope, unit K:
coefficients 1.5e-8, logLik 1.5e-5; NB2 animal slope: 1.1e-7, 1.9e-6), b25 (Gamma
relmat slope 2.6e-7, 3.1e-6; Gamma spatial slope 2.9e-7, 1.1e-5; NB2 relmat slope
6.8e-8, 4.8e-6) and b26 (NB2 spatial slope 1.4e-7, 1.9e-6). No `test-julia-poisson-relmat*`
live file exists.

## 6. Tests of the Tests

The new Julia test would fail if `K` were normalised: the fit's objective matches
the raw-`K` oracle within 2e-3, and the correlation-rescaled oracle differs by
more than 0.05 at the same parameters (asserted). The first run of the fixture
gave a gap of 0.046 for one family at a random-effect SD of 0.35, below the 0.05
bar; the fixture SD was raised to 0.6 rather than the bar lowered. Before the
source change, the four existing tests passed on the normalised objective and
failed on the raw one (the 15 failures in the first run are the evidence that the
tests do pin the scale).

## 7a. Issue Ledger

- Existing Julia tests changed (all because they asserted normalised-K behaviour):
  `test_poisson_relmat_sd_regression.jl`, `test_gamma_relmat_sd_regression.jl`,
  `test_poisson_relmat_slope_sd_regression.jl`: the fixture drew the latent field
  from the correlation matrix and the oracle used it; both now use the raw `K`.
  `test_nb2_relmat_sd_regression.jl`: the scale-invariance assertion (scaled `K`
  equals the correlation fit) is replaced by a raw-`K` oracle check and by an
  assertion that the two fits differ. No tolerance was loosened.
- Existing R test changed: `test-julia-b18-relmat-nb2-slope-sd-bridge.R` (not in
  the evidence ledger, so no receipt to re-record). No receipted R test changed.

## 8. Consistency Audit

Fit, `predict_parameters`, `simulate` and bootstrap now use the same `K` on the
Poisson, NB2 and Gamma relmat routes (the two simulators were the only other
places that rebuilt the covariance). The ordinary-simulate path
(`_resolve_structured_matrix`) was already raw. The R bridge sends `K` unchanged.

## 9. What Did Not Go Smoothly

- The first fixture of the new test was too weak to separate raw from rescaled
  `K` for one family (section 6).
- The first live run failed only because the new test's helper compared the
  wrong coefficient container and its formula needed `K` to be a named object;
  both were test bugs, not engine differences.
- The private R copy is 3.6 GB; a baseline `git add` over it was too slow, so the
  patch was produced with `diff -u` over the touched files.

## 10. Known Residuals

Open parity rows (read from source, not measured live; also listed in the design
doc): Beta relmat/animal (`beta.jl:243`) and zero-one-beta and Gaussian
location-scale structured routes still rescale `K` or `A`. Binomial and Tweedie
relmat SD routes use `K` raw in source; no tight non-unit-diagonal live check
exists for Binomial (the old test uses tolerance 0.1). Hurdle, `zi` and
cumulative-logit relmat/animal are refused in Julia. Precomputed-`K` spatial
intercepts still rescale. No coverage, calibration or broad parity claim is made.
`test_cox_reid_poisson_phylo.jl` and `test_temporal_ar1.jl` were not run (missing
StableRNGs in the copied Totoro environment).

## 11. Team Learning

- A "non-unit K" test must have enough signal to separate raw from rescaled `K`;
  assert the separation, not only the match.
- When flipping a scale convention, search the simulators and bootstrap: they
  rebuilt the covariance separately.
- Julia test fixtures that draw the latent field from a different matrix than the
  fit uses can pass for the wrong reason; draw from the matrix the model uses.

## 12. Cross-Product Coverage

Covered: Poisson, NB2, Gamma by relmat intercept and relmat slope-only SD, on
both engines, at one non-unit-diagonal fixture each. Not covered: Beta,
zero-one-beta, Binomial constant-SD relmat, Tweedie live parity, `Ainv`/`Q`
precision inputs, labelled q2 relmat, REML, missing-response and interval
calibration.
