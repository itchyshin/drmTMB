# Metamorphic invariance of the Julia SD-regression routes

Lane: creative, 2026-11-08. No R oracle is used. Each check transforms the input in a way whose exact
effect on the log-likelihood and the estimates is known, refits with DRModels.jl, and compares.
A property that fails is a finding (real defect or expected non-equivariance).

- Julia repo: `itchyshin/DRModels.jl`, branch `claude/metamorphic-20261108` (from
  `origin/claude/binomial-phylo-spatial-q2-20261108` @ `759e58e4f`), commit `80e1ec1f3`, one new file
  `test/test_metamorphic_sd_routes.jl`. Nothing under `src/` was changed. Not merged, no PR.
- Toolchain: Julia 1.10.0 (the Mac default; the committed fixtures were generated on 1.10.12), one thread,
  `OPENBLAS_NUM_THREADS=1`, `nice -n 10`, at most two of my Julia processes at a time on the shared Mac Studio.
  Totoro was not needed (all fits are sub-second to a few seconds). R was not run.
- Run: `julia --project=test -e 'using DRModels, Test; include("test/test_metamorphic_sd_routes.jl")'`
  (fast subset, 191 checks: 3 min 20 s and 3 min 32 s in two runs, including compilation, on a shared machine with another of my fit processes or other lanes running;
  followed in the same process by `test_skewnormal.jl`, which still passes, 6 s).
  `METAMORPHIC_FULL=1 METAMORPHIC_OUT=results.tsv` runs the full matrix below (511 checks, 7 min 40 s).
- Data: StableRNG-generated (24 groups x 10 rows; 32 x 24-28 for the binomial animal route) or the committed
  fixtures `test/fixtures/q2_stable/*.tsv` and `binomial_phylo_spatial_q2/*.tsv` (32 tips) for the phylo and
  spatial routes. A synthetic mean covariate `v` (true coefficient 0.2) is added to every fit.

## Properties

| property | transformation | predicted effect |
|---|---|---|
| perm | shuffle data rows (A re-ordered to first-seen order) | logLik and all estimates unchanged |
| relabel | permute whole group blocks and rename levels (A, tree tips, coordinates keyed consistently) | unchanged |
| shift v | `v -> v + c`, `v` only in the mean | intercept `-= beta_v c`, rest unchanged |
| shift w | `w -> w + c` in every SD formula | each SD intercept `-= a_w c`, logLik unchanged |
| scale w | `w -> k w` | each SD slope `/= k`, logLik unchanged |
| scale x | `x -> k x`, `x` is the random-slope covariate | `beta_x / k`, SD(x) intercept `- log k`, correlation unchanged |
| flip x | `x -> -x` | `beta_x -> -beta_x`, SDs unchanged (correlation sign flips, not compared) |
| shift x | `x -> x + c` with `sd ~ w` formulas on the slope | **not** equivariant (see F1); reported only |
| shift x, const SD | `x -> x + c` with constant SDs and a free correlation | logLik unchanged (positive control for F1) |
| scale y | Gaussian `y -> k y` (Gamma likewise) | beta `x k`, log sigma `+ log k`, SD intercepts `+ log k`, logLik `- n log k` |
| predict | `predict(fit, training data)` vs `fitted(fit)`; `predict_parameters` vs `fit.scales`; predict on shuffled rows | equal; equivariant |
| swap | `(x + 1 \| g)` instead of `(1 + x \| g)` | same fit |
| REML | `method = :REML` (Gaussian structured q2): perm, relabel, shift v | REML logLik unchanged |
| sim-refit | simulate with the package simulator (or from the true generative process where `simulate` refuses), refit, 5 datasets | median error within tolerance; truth never beats the refit optimum: `nll(truth) - nll(fit) > -1e-3` |

Tolerances: `|dlogLik| < 1e-5` and `max|dtheta| < 1e-3` for the exact properties; sim-refit `|median error|
< 0.25` (fixed effects), `< 1.0` (SD coefficients), with per-route overrides listed under "What I changed
after seeing results". Status words: `pass`; `FLAT` = logLik agrees but an estimate does not (flat direction,
usually the correlation at its boundary); `weak` = sim-refit tolerance missed but the truth does not beat the
fit; `expected` = a property that is not meant to hold (F1); `NA` = not applicable to the route;
`refused` = the route does not exist in Julia (explicit error).

## Result matrix (35 routes x 14 properties; `results-full.tsv` has every number)

Routes: `gauss_ord_q2/q3/q4` ordinary Gaussian `(1 + x [+ z [+ u]] | id)` with one SD formula per coefficient;
`*_ord_q2` Poisson, NB2, Gamma, Binomial ordinary; `*_animal_q2`, `*_phylo_q2`, `*_spatial_q2` independent-field
structured q2; `*_lab_*` labelled `(1 + x | p | id)` (free correlation); `*_q1` `(1 | id)` with `sd(id) ~ w`;
`*_sigma_*` structured sigma random effect with `sd(id, [level,] sigma) ~ w`.

| route | base fit | perm | relabel | shift v | shift w | scale w | scale x | flip x | shift x | shift x, const SD | scale y | predict | swap | REML | sim-refit |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `gauss_ord_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | pass | pass | pass | NA | pass |
| `gauss_ord_q3` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | pass | pass | NA | NA | pass |
| `gauss_ord_q4` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | pass | pass | NA | NA | pass |
| `pois_ord_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `nb2_ord_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `gamma_ord_q2` | refused | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| `binom_ord_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `gauss_animal_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | pass | pass | pass | pass | pass |
| `pois_animal_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `nb2_animal_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `gamma_animal_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | pass | pass | pass | NA | pass |
| `binom_animal_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `gauss_phylo_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | pass | pass | pass | pass | pass |
| `gauss_spatial_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | pass | pass | pass | pass | pass |
| `pois_phylo_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `pois_spatial_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `nb2_phylo_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `nb2_spatial_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `binom_phylo_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `binom_spatial_q2` | pass | pass | pass | pass | pass | pass | pass | pass | expected | NA | NA | pass | pass | NA | pass |
| `pois_lab_ord` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `nb2_lab_ord` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `pois_lab_animal` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `nb2_lab_animal` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | weak |
| `gauss_lab_animal` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | pass | pass | pass | NA | pass |
| `pois_lab_phylo` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `pois_lab_spatial` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `nb2_lab_phylo` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | NA | pass | pass | NA | pass |
| `gauss_lab_phylo` | pass | pass | pass | pass | pass | pass | pass | pass | expected | pass | pass | pass | pass | NA | pass |
| `gauss_q1` | pass | pass | pass | pass | pass | pass | pass | pass | pass | NA | pass | pass | NA | NA | pass |
| `pois_q1` | pass | pass | pass | pass | pass | pass | pass | pass | pass | NA | NA | pass | NA | NA | pass |
| `gauss_sigma_ord` | pass | pass | pass | pass | pass | pass | pass | pass | pass | NA | pass | pass | NA | NA | pass |
| `gauss_sigma_animal` | pass | pass | pass | pass | pass | pass | pass | pass | pass | NA | pass | pass | NA | NA | pass |
| `nb2_sigma_animal` | pass | pass | pass | pass | pass | pass | pass | pass | pass | NA | NA | pass | NA | NA | pass |
| `gamma_sigma_animal` | pass | pass | pass | pass | pass | pass | pass | pass | pass | NA | pass | pass | NA | NA | pass |

Totals over the 511 cells of the final full run: 402 pass, 79 NA, 28 expected (shift x), 1 refused, 1 weak,
**0 FAIL**. The zero is after the changes listed below; the first exploratory runs did find failures.

Numerical envelope of the passing exact checks (`results-full.tsv`): max |dlogLik| is 4e-7 for every property
(perm 3e-9, relabel 3e-7, shift v 4e-7, shift w 3e-7, scale w 3e-7, scale x 2e-7, flip x 4e-8, shift x const
5e-10, scale y 2e-10, REML 3e-13); max |dtheta| is 2e-7 (perm, relabel), 7e-5 (shift v), 9.4e-4 (shift w, scale w),
1e-4 (scale x). The two 9.4e-4 values are both `binom_animal_q2`, which is within a factor 1.1 of the 1e-3
tolerance: that route (Binomial animal q2) has a nearly flat optimum, so estimates move at 1e-3 while the logLik
agrees to 1e-7.

## Findings

**F1. Expected non-equivariance: shifting the random-slope covariate with `sd ~ w` formulas (28 routes).**
`x -> x + c` changes the logLik by between -3.1 (`gauss_spatial_q2`) and +5.0 (`binom_phylo_q2`), in both
directions, with converged refits in 26 of the 28 (`binom_animal_q2` and `pois_lab_phylo` did not converge after the shift). Reason: b0' = b0 + c b1, so Var(b0') = s0^2 + c^2 s1^2 + 2 c rho s0 s1, which is
not of the form exp(2(a + a_w w)) once s0 and s1 depend on different covariates; the transformed model is a
different model, not a reparametrisation. It is not a defect. Positive control: with constant SDs and a free
correlation (15 routes: ordinary q2/q3/q4, labelled) the same shift leaves the logLik unchanged (max 5e-10) and
moves the intercept by `-beta_x c`. Routes where `x` has no random slope (q1 and sigma routes, 6) are exactly
shift-equivariant (`shift x` column `pass`). Independent-field structured routes (rho fixed 0) are not closed under
the shift even with constant SDs, so `shift x, const SD` is `NA` there.

**F2. Real defect (low severity, robustness): NB2 structured-sigma "shape B" (`sigma ~ 1 + animal(1 | id)`,
`sd(id, animal, sigma) ~ w0`; Julia-only, no R twin) throws instead of returning a non-converged fit.**
Reproducer: `repro-nb2-sigma-animal/repro.jl` (240 rows, 24 animals; `data.csv`, `A.csv`).
At the committed generation seed 20261108 the fit returns `converged = false` (logLik -354.53), and the identical
model with `w0` multiplied by 2.5 (a pure reparametrisation, `a_w -> a_w / 2.5`) raises
`PosDefException: matrix is not positive definite` from `src/sigma_structured_laplace.jl:107` (Cholesky of the
dense Laplace Hessian, evaluated inside the ForwardDiff gradient), aborting `drm`. Over data seeds 1-8
(`seedscan.tsv`): 5 pass, seed 4 does not converge (row permutation then moves the logLik by 1.9), seeds 5 and 8
reach `converged = true` at degenerate optima (|theta| 14-15; seed 5 has SD-formula coefficients -13.95 and +14.09) where
the estimates are not unique. Gamma shape B (8/8) and Gaussian sigma-animal (8/8) pass every seed. Likely cause
(inference, not checked): at the failing fits log sigma is about -2.1 against a true -0.69, i.e. the NB2 dispersion
is near the Poisson limit where a dispersion random effect is unidentified. The defect proper is the uncaught
exception; the non-convergence flag itself is honest. The tests use seed 1 for this route.

**F3. Boundary flat directions (expected, not a defect).** In the seed scan (144 base fits of 18 non-fixture routes,
8 seeds) 12 fits are `FLAT`: `dlogLik < 1e-5` under row permutation, yet some estimate differs, with `max|theta|`
between 8.0 and 15.4. Routes: `pois_ord_q2` (2), `pois_lab_ord` (3), `nb2_lab_ord` (3), `nb2_lab_animal` (2),
`nb2_sigma_animal` (2). The size of theta is consistent with the correlation parameter running to its boundary
(tanh -> 1); I did not separately print each correlation. At the default test seeds none occurs. The first full
run also showed it for `pois_lab_animal` and `nb2_lab_animal` at the original seed (all refit properties `FLAT`) and
for the first, small binomial fixtures (`binom_ord_q2`, `binom_animal_q2`: loglik equal to 1e-8, estimates 0.1-0.6
apart, some refits `converged = false`), which is why those fixtures were strengthened (below).

**F4. `simulate(fit; data, ...)` refuses on Gaussian ordinary `(1 + x [+ ...] | g)` SD routes and on Gaussian
sigma random-effect routes (feature gap, explicit error).** Messages: q2 "LSS bootstrap supports ordinary
intercepts and independent numeric slopes only"; q3 "DRModels.jl supports `(1 | g)`, `(0 + x | g)`,
`(1 + x | g)`"; sigma routes "LSS bootstrap requires ordinary mean effects and fixed residual-scale predictors".
The sim-refit check therefore used the true generative process on those five routes (`gauss_ord_q2/q3/q4`,
`gauss_sigma_ord`, `gauss_sigma_animal`; marked `truth` in `results-full.tsv`; the q4 message was not recorded separately), so `simulate` itself is untested
there. Whether drmTMB simulates these models was not checked.

**F5. Term order and the `swap` property.** `(x + 1 | g)` is parsed to exactly `(1 + x | g)` (26 routes, dlogLik 0,
dtheta 0), so `swap` shows that term order is normalised, not that an x-first parametrisation is equivalent.
The spelling `(0 + x + 1 | g)` is refused: StatsModels keeps both constant terms (`0 + 1 + x`) and DRModels
raises "Poisson random-effect SD regression requires exactly one SD target" (Poisson) or "sd() supports random
INTERCEPT terms only" (Gaussian). R's `y ~ 0 + x + 1` keeps the intercept, as far as I recall (not checked here).
Explicit refusal of an exotic spelling, not a wrong answer.

**F6. `fit.scales[:sigma]` is not `predict_parameters(fit, data)[:sigma]` on structured-sigma routes.** The first
is the conditional sigma including the random effect, the second the population-level value (difference up to
3.0); `fit.scales[:sigma_fixed]` equals it exactly. By design, but a naming trap. The `predict` property compares
against `:sigma_fixed`.

**F7. `gamma_ord_q2` does not exist:** Gamma ordinary `(1 + x | g)` with two SD formulas raises "Gamma
random-effect SD regression requires exactly one SD target" (Poisson and NB2 ordinary q2 exist).

**F8. Weak identification in sim-refit (statistical, not a defect).** The truth never beat a refit optimum on any
route (smallest `nll(truth) - nll(fit)` is +1.02, over 34 fitted routes x 5 datasets). Median error of SD-formula
coefficients is above 1.0 on `nb2_animal_q2` (1.04), `nb2_spatial_q2` (1.12) and, on the committed NB2 phylo
fixture, **9.07** (a boundary run-away in most of the 5 refits; this route's SD tolerance is switched off, so its
SD recovery is unchecked). `binom_spatial_q2` has fixed-effect median error 0.527 (above the default 0.25; passes only under the raised 0.6) and
`nb2_lab_animal` misses 0.25 (0.291; the one `weak` cell). Count and binary responses at G = 24-32
identify SD-formula slopes poorly; Gaussian routes recover them within 0.07-0.59.

## What I changed after seeing results (so the zero FAIL is not a clean pre-registered pass)

- Tolerances for the exact properties (1e-5, 1e-3) were set before the first run and never changed.
- sim-refit: first version compared the mean error with SD tolerance 0.9; after boundary run-aways dominated the
  mean, it was changed to the median over datasets with tolerance 1.0. Per-route overrides added after the first
  full run: NB2 animal and spatial 1.5, NB2 phylo off, binary routes 3.0 (SD) and 0.6 (fixed; `binom_spatial_q2`
  0.527), none for the others. Datasets per route raised 4 -> 5: at 4 the median of `binom_phylo_q2` was 5.1.
- Binomial ordinary and animal fixtures strengthened (SD 0.9 / 0.8, 24-28 rows per group, 32-48 groups) after the
  first fixtures (16 rows, 30 groups) sat on a flat optimum.
- Generation seeds fixed to 1, 2 and 1 for `pois_lab_animal`, `nb2_lab_animal` and `nb2_sigma_animal` (original seed
  20261108 gives boundary or non-converged fits, F2 and F3); the datasets also changed once when a fourth covariate
  column `u` was added to the generator for q4.
- `gauss_ord_q3` runs only 4 properties in the fast default subset to keep the file under 5 minutes; the full
  matrix runs all of them.

## Not verified

- R side: nothing here compares with drmTMB; every check is Julia-internal. A pass does not show the likelihood is
  right (a consistently wrong likelihood can still be invariant); it shows indexing, ordering, naming and
  parametrisation do not leak into the answer.
- Julia 1.11 / 1.12 / 1.13 (only 1.10.0 here), more than one thread, other optimiser settings, larger G.
- The bridge (`drm_bridge`) and R-formula-string path; bootstrap and profile intervals; `se = true` standard errors
  (all non-Gaussian fits used `se = false`); q4 REML; labelled REML; Tweedie, ZIP, beta families and the rest of
  the SD-regression routes not listed in the matrix.
- Whether the FLAT fits really have the correlation at +-1 (inferred from |theta|); the cause in F2 is inferred.
- The fast default subset (17 routes, 191 checks) was run end to end, followed by `test_skewnormal.jl` in the same
  process, on exactly the committed code `80e1ec1f3`; the full matrix was run on the same code except for the
  comment-only header edit made just before the commit.

## Files

`results-full.tsv` (route, property, status, detail, seconds), `seedscan.tsv` + `seedscan.jl` (8-seed scan of base
fits), `repro-nb2-sigma-animal/` (F2 reproducer and data), `dump-repro-data.jl` (how the data were written).
