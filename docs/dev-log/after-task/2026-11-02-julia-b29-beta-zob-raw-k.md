# After-task report: batch 29, Julia uses relmat K and animal A as supplied (Beta, ZeroOneBeta)

Date: 2026-11-02. Reader: Shinichi, and the next agent on the general-sd-regression lane.

## 1. Goal

Extend batch 28: DRModels.jl uses a supplied `relmat()` kernel `K` and `animal()` matrix `A`
unchanged (raw) on the Beta and ZeroOneBeta routes, as native drmTMB does. `phylo()` keeps
the correlation form.

## 2. Implemented

Julia (DRModels.jl commit `d5e3e6b11` on `codex/general-sd-regression`, pushed):

- `src/sparse_laplace_glmm.jl`: `_fit_beta_relmat_laplace` gained `normalize::Bool = false`
  and passes it to `_general_cov_setup`; docstring updated.
- `src/zeroonebeta.jl`: `_fit_zeroonebeta_relmat_laplace` gained the same keyword; the call
  site passes `normalize = kind === :spatial`.
- `src/beta.jl`: the intercept call site passes `normalize = kind === :spatial`; the
  `sd(group, animal)` objective `_beta_animal_sd_laplace_nll` calls
  `_general_cov_setup(A, gidx; normalize = false)`; comments and the docstring now say raw.
- `src/inference.jl`: `_beta_animal_sd_marginal_simulator` draws from the Cholesky factor of
  the raw `A`, so fit, predict, simulate and bootstrap agree.
- Tests: new `test/test_beta_zob_raw_k_regression.jl`; `test/test_beta_animal_sd_regression.jl`
  changed (section 7a).

R (this patch): new `tests/testthat/test-julia-b29-beta-zob-raw-k-bridge.R`, `NEWS.md`,
`docs/design/18-random-effect-scale-models.md`, this note. `R/julia-bridge.R` is unchanged.

## 3a. Decisions and Rejected Alternatives

- Raw `K` and `A`, per the owner's decision in batch 28.
- The precomputed spatial intercept keeps its rescaling (`normalize = kind === :spatial`),
  as in batch 28. The Beta `sd(g, animal)` route is always raw.
- `_general_cov_setup` keeps its default (`true`): the Gaussian location-scale routes still
  call it without the keyword.
- Gaussian location-scale (`src/locscale_fit.jl:353`, `_locscale_relmat_setup`) was reviewed
  and NOT changed. It still rescales `K` to a correlation matrix. Changing it also moves the
  structured location-scale slope helper `_locscale_structured_q`, and no native
  comparator or tests were run for those routes in this batch. It stays an open row.
- Rejected: adding Beta and ZeroOneBeta structured routes to the R bridge. That is a
  separate feature, not a scale fix.

## 4. Files Touched

Julia: `src/beta.jl`, `src/inference.jl`, `src/sparse_laplace_glmm.jl`, `src/zeroonebeta.jl`;
tests `test/test_beta_zob_raw_k_regression.jl` (new), `test/test_beta_animal_sd_regression.jl`.
R (patch): `NEWS.md`, `docs/design/18-random-effect-scale-models.md`,
`tests/testthat/test-julia-b29-beta-zob-raw-k-bridge.R` (new), this note (new).
Julia docs (`docs/src/families.md`, `capabilities.md`, `tutorials/animal-models.md`) still
describe Beta animal as rescaled; they carry unrelated uncommitted edits in that worktree
and were not committed.

## 5. Checks Run

Julia, on Totoro (Julia 1.10.12, `JULIA_NUM_THREADS=1`, cores 198-203):

| File | Result |
|---|---|
| `test_beta_zob_raw_k_regression.jl` (new) | 24 pass, 0 fail, 0 error |
| `test_beta_animal_sd_regression.jl` (changed) | pass, no failure |
| `test_relmat_counts_beta.jl`, `test_twin_gap_739.jl`, `test_zeroonebeta.jl` | pass, no failure |
| `test_bootstrap_formula_structured.jl`, `test_bootstrap_nongaussian_structured.jl`, `test_locscale_bootstrap_simulator.jl` | pass, no failure |
| `test_ordinary_laplace.jl`, `test_api_stability.jl`, `test_relmat_raw_k_regression.jl` | pass, no failure |

Live native-versus-Julia (Mac, Julia 1.10.0, `NOT_CRAN=true`, one R process at a time;
tolerances fixed before running: coefficients 1e-3, logLik 1e-2, native `se = FALSE`; Julia
called directly through JuliaCall because the bridge does not route these families):

| Route (non-unit-diagonal K or A) | max coefficient diff | logLik diff |
|---|---|---|
| Beta `relmat(1 | id)` | 1.0e-8 | 8.8e-11 |
| Beta `animal(1 | id)` | 1.0e-8 | 8.8e-11 |
| ZeroOneBeta `relmat(1 | id)` | 2.4e-11 | 1.8e-12 |
| ZeroOneBeta `animal(1 | id)` (native with `Ainv = solve(A)`) | 2.4e-11 | 1.9e-12 |
| Beta `animal(1 | id)` with `sd(id, level = "animal") ~ z` | 5.0e-8 | 3.6e-10 |

The compared vector is mu, sigma, log SD (or SD regression coefficients), and for
ZeroOneBeta also zoi and coi.

## 6. Tests of the Tests

The new Julia test compares each fit's objective at its optimum with a dense Laplace oracle
coded from the raw `K` (differences 6e-13 to 3e-10, tolerance 2e-3). Emulated bugs are
asserted to move the oracle by more than 0.05: correlation-rescaled `K` (gaps 0.54 to 13.7),
`K` left in label order instead of first-seen order (gaps 1.3 to 4.2), a reversed group SD
vector (gap 2.5), and a bootstrap draw from the correlation factor (draw differs by more than
0.1). The old normalised objective would fail every oracle comparison.
The existing Beta animal SD test passed on the normalised objective and was changed to raw.

## 7a. Issue Ledger

- Existing Julia test changed: `test_beta_animal_sd_regression.jl`. The oracle built
  `Q` from the correlation-rescaled `A`, the fixture drew the latent field from the
  correlation matrix `R`, and the simulator check used the rescaled factor. All three now use
  the raw `A`. No tolerance was changed.
- The task expected a Beta/ZeroOneBeta non-unit-K refusal in `R/julia-bridge.R`. None exists:
  `drm_julia_structured_family_tag()` aborts for these families before any K check.

## 8. Consistency Audit

Fit, predict, simulate and bootstrap agree on the raw scale for the Beta animal SD route
(the bootstrap simulator was the only other place that rebuilt the covariance). Beta and
ZeroOneBeta constant-SD intercept simulation goes through the ordinary path
(`_resolve_structured_matrix`), already raw. A search for `normalize`, `cov2cor` and
`d * d'` found only the Gaussian location-scale helper and the spatial intercept as remaining
rescaling sites.

## 9. What Did Not Go Smoothly

- The first Totoro rsync (relative destination) copied nothing silently; an absolute
  destination worked.
- The registry note "beta has NO_NATIVE_COMPARATOR" in `R/julia-bridge.R` is stale: native
  `relmat()` on `beta_family()` exists (`test-beta-relmat.R`) and was used as the comparator.
  It was not edited here.
- Zero-one-beta animal needs `Ainv` natively, so the native side used `solve(A)`.

## 10. Known Residuals

Open parity rows: Gaussian location-scale structured routes (`locscale_fit.jl:353`) still
rescale; precomputed spatial intercepts still rescale; Beta and ZeroOneBeta are not routed by
the R bridge; Beta relmat SD regression and ZeroOneBeta SD with structured terms are not
implemented in Julia. No coverage, calibration or broad parity claim.

Environment sensitivity found by the verifier: the Beta animal `sd(id, level = "animal") ~ z`
block of `test-julia-b29-beta-zob-raw-k-bridge.R` passes in the Julia worktree (coefficients
within 5.0e-8, logLik within 3.6e-10) but failed in a clean `git archive` copy, where the Julia
optimiser stopped about 0.95 log-likelihood units short of the native optimum while reporting
convergence (Julia's own objective at the native optimum matched native exactly, so the raw-K
objective is right). `Manifest.toml` is gitignored in DRModels.jl, so a clean copy resolves its
dependencies afresh, probably to different optimiser versions. This is a Julia optimiser
robustness question for the Beta animal SD route, not a scaling question. The tolerances were
not loosened and the block stays; run it in an environment that uses the worktree's resolved
manifest. Open item: pin or document the dependency set the parity checks rely on.

## 11. Team Learning

- Check whether a refusal exists before planning its removal: the family gate came first.
- Native `zero_one_beta()` animal takes `Ainv`, not `A`.
- When the bridge cannot route a family, direct JuliaCall against native is still a valid
  same-data parity check; say so in the file header.

## 12. Cross-Product Coverage

Covered: Beta relmat and animal intercept, ZeroOneBeta relmat and animal intercept, Beta
animal SD ~ z, each at one non-unit-diagonal fixture on both engines. Not covered: spatial,
phylo, Beta relmat SD, Gaussian location-scale, `Q`/`Ainv` for Beta, REML, SEs, intervals.
