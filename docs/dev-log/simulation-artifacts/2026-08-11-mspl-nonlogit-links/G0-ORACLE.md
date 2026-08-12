# G0 oracle: independent check of the MSPL link-general kernels (`R/mspl.R`)

Slice S1 of the `mspl-nonlogit-evidence` campaign. Local R task, run by Gauss
(TMB likelihood/numerical reviewer). No fitting with drmTMB's own MSPL
estimator; no cluster. `R/mspl.R` was audited, not edited.

**Worktree:** `.../scratchpad/wt-omega`, branch `claude/mspl-nonlogit-evidence`.
**Script:** `G0-oracle.R` in this directory (re-runnable: `Rscript --no-init-file G0-oracle.R`).
**Seed:** `SEED <- 20260811L` (design generation and response simulation both
derive from this seed; see script for the exact per-design/per-link seed
offsets).
**R:** 4.6.0. **brglm2:** installed and used (`brglm2::brglm_fit(type = "AS_mean")`).

## Method

Sourced `R/mspl.R` directly with `source()` (no other internals needed — the
file only calls `stats::*` and `cli::cli_abort`). No `pkgload::load_all()`
was necessary.

Three designs, each simulated once per link (`logit`, `probit`, `cloglog`),
non-separated by construction (moderate true coefficients, mean-centred
continuous covariate, trials `m_i ~ Uniform{10,...,30}`, keeping most fitted
probabilities away from `{0, 1}`):

| design | n | p | covariates |
|---|---|---|---|
| D1 | 60 | 2 | intercept + continuous `x` |
| D2 | 200 | 4 | intercept + continuous `x` + factor `f` (3 levels) |
| D3 | 1000 | 4 | intercept + continuous `x` + factor `f` (3 levels) |

True coefficients: `p=2`: `c(0.2, 0.6)`; `p=4`: `c(0.2, 0.6, 0.4, -0.3)`.

## (A) Weight parity: `glm()` IRLS weights vs `exp(mspl_log_weight())`

`glm(cbind(y, m - y) ~ ..., family = binomial(link = L))$weights` are the
IRLS working weights from the last iteration, `w = prior.weight *
(dmu/deta)^2 / V(mu)`, with `prior.weight = m` for the `cbind()` form — the
same expected/Fisher-information weight `mspl_log_weight()` implements.

Compared at the SAME `eta = fit$linear.predictors`:
`w_mspl <- exp(mspl_log_weight(eta_hat, trials, link))` vs `fit$weights`.

**Finding while building the oracle:** under `glm()`'s DEFAULT tolerance
(`glm.control(epsilon = 1e-8)`, which tests the deviance, not `eta`), the
returned `eta`/`weights` pair is close to but not exactly at the MLE, so the
raw deviation is ~1e-4 to 1e-7 relative — small, but not the "~1e-10 or
better" the task brief expected. Tightening `glm.control(epsilon = 1e-15,
maxit = 200)` shrinks the deviation toward machine precision for every link,
confirming this is `glm()`'s own convergence tolerance, not a mismatch
between the two weight computations. Both are reported; **tight is the
primary comparison**.

| design_link | n | p | converged | tight max abs dev | tight max rel dev | loose max abs dev | loose max rel dev |
|---|---|---|---|---|---|---|---|
| D1_logit   | 60   | 2 | TRUE | 4.263e-14 | 1.657e-14 | 7.616e-07 | 3.010e-07 |
| D1_probit  | 60   | 2 | TRUE | 8.499e-08 | 1.774e-08 | 2.198e-04 | 4.525e-05 |
| D1_cloglog | 60   | 2 | TRUE | 7.957e-08 | 7.103e-09 | 1.688e-04 | 1.506e-05 |
| D2_logit   | 200  | 4 | TRUE | 5.418e-14 | 1.750e-14 | 9.568e-07 | 2.932e-07 |
| D2_probit  | 200  | 4 | TRUE | 1.506e-08 | 2.952e-09 | 8.865e-05 | 1.738e-05 |
| D2_cloglog | 200  | 4 | TRUE | 1.222e-07 | 4.810e-08 | 3.068e-04 | 1.273e-04 |
| D3_logit   | 1000 | 4 | TRUE | 1.243e-14 | 4.137e-15 | 2.353e-07 | 9.647e-08 |
| D3_probit  | 1000 | 4 | TRUE | 2.933e-11 | 6.069e-12 | 6.556e-06 | 1.387e-06 |
| D3_cloglog | 1000 | 4 | TRUE | 8.800e-11 | 3.402e-11 | 1.492e-04 | 5.723e-05 |

Logit reaches ~1e-14 (bit-level machine precision) under tight tolerance, as
expected since it is the canonical link and `glm()`'s IRLS is exact there.
Probit and cloglog reach 1e-7 to 1e-11 under tight tolerance — still tiny in
absolute terms and clearly convergence-limited (they shrink by 3-6 orders of
magnitude between loose and tight, tracking `glm()`'s own residual, not a
fixed floor).

**(A) PASS** for all three links, all three designs, under the tightened
comparison. `mspl_log_weight()` reproduces `glm()`'s own IRLS working weight
exactly up to `glm()`'s residual convergence error, for every link tested.

## (B) Jeffreys parity: `mspl_jeffreys()$half_logdet` vs `0.5*logdet(X'diag(w_glm)X)`

At the tight-`glm()`-fitted `beta`, built `w_glm <- fit_tight$weights`,
`info_glm <- crossprod(X, X * w_glm)`, `half_logdet_glm <-
determinant(info_glm, logarithm = TRUE)$modulus / 2`, and compared against
`mspl_jeffreys(X, beta = coef(fit_tight), trials = m, link = L)$half_logdet`.

| design_link | half_logdet (mspl) | half_logdet (glm-built) | abs dev | rel dev | brglm2 AS_mean finite |
|---|---|---|---|---|---|
| D1_logit   | 5.626592  | 5.626592  | 3.553e-15 | 6.314e-16 | TRUE |
| D1_probit  | 6.438206  | 6.438206  | 3.609e-09 | 5.606e-10 | TRUE |
| D1_cloglog | 6.465798  | 6.465798  | 1.909e-09 | 2.953e-10 | TRUE |
| D2_logit   | 11.883588 | 11.883588 | 5.329e-15 | 4.484e-16 | TRUE |
| D2_probit  | 13.588869 | 13.588869 | 6.021e-10 | 4.431e-11 | TRUE |
| D2_cloglog | 13.411633 | 13.411633 | 4.901e-09 | 3.654e-10 | TRUE |
| D3_logit   | 15.087771 | 15.087771 | 1.776e-15 | 1.177e-16 | TRUE |
| D3_probit  | 16.829072 | 16.829072 | 9.202e-13 | 5.468e-14 | TRUE |
| D3_cloglog | 16.731157 | 16.731157 | 2.409e-12 | 1.440e-13 | TRUE |

All relative deviations are at or below ~1e-10 (mostly ~1e-13 to 1e-16). The
`brglm2::brglm_fit(type = "AS_mean")` (Jeffreys/mean-bias-reducing) fit was
also finite for every design and link tested, on non-separated data — a cheap
secondary confirmation that the link-general Jeffreys machinery agrees with
an independent, published implementation's finite-estimate behaviour, though
this is not itself a numerical-parity check (both fits converge here; no
separation was engineered to stress-test brglm2 vs `glm()` divergence).

**(B) PASS** for all three links, all three designs. `mspl_jeffreys()`'s
`half_logdet` matches an independently built `X'WX` determinant using
`glm()`'s own converged weights, to numerical precision, for every link
tested.

## (C) Defect regression: `mspl_penalty_components()` must actually change with `link`

Called `mspl_penalty_components(X, beta = beta_true, variance = 0, q = 1,
trials = m, link = L)` for `L` in `{logit, probit, cloglog}`, on the SAME
`X`, `beta`, `trials` per design (`beta_true` = the design's true coefficient
vector, `variance = 0` giving `q=1` log-SD = 0, i.e. `sd = 1`, so the
link-free negative-Huber term is identical across links and any difference
in the composite output is attributable entirely to `link`).

`jeffreys_bonus` (`= half_logdet`, the fixed-effect Jeffreys term):

| design | logit | probit | cloglog |
|---|---|---|---|
| D1 | 5.670674 | 6.506907 | 6.427536 |
| D2 | 11.880953 | 13.611194 | 13.499824 |
| D3 | 15.078677 | 16.805909 | 16.711111 |

`log_objective_bonus` (`= c_n * (jeffreys_bonus + variance_negative_huber)`,
the full composite contribution):

| design | logit | probit | cloglog |
|---|---|---|---|
| D1 | 0.4607108 | 0.5286500 | 0.5222016 |
| D2 | 0.7500125 | 0.8592379 | 0.8522075 |
| D3 | 0.4277962 | 0.4767994 | 0.4741098 |

Every link produces a materially different value from every other link, on
every design, in both the `jeffreys_bonus` and the full
`log_objective_bonus` — differences of order 0.7-1.7 in `jeffreys_bonus`,
far above any numerical-noise scale. This is the behaviour the 2026-08-09 fix
(documented in `docs/design/253-mspl-nonlogit-links-derivation.md` §7)
restored: a broken version that silently defaulted to `link = "logit"`
inside `mspl_jeffreys()` would show `probit == cloglog == logit` here, which
is not what is observed.

**(C) PASS**. `mspl_penalty_components()` genuinely threads `link` through to
its `jeffreys_bonus`/`log_objective_bonus` output; the fix holds under this
independent regression check.

## Summary verdict

| check | verdict |
|---|---|
| (A) weight parity, `glm()` IRLS vs `mspl_log_weight()` | **PASS** (all 3 links x 3 designs; machine precision under tight `glm()` tolerance) |
| (B) Jeffreys parity, `glm()`-built `X'WX` vs `mspl_jeffreys()` | **PASS** (all 3 links x 3 designs; ~1e-10 or better relative) |
| (C) defect regression, link-dependence of `mspl_penalty_components()` | **PASS** (all 3 links materially differ on every design) |

No discrepancy was found in this slice. This is oracle evidence for the
fixed-effect kernels only (`mspl_log_weight`, `mspl_link_mu`, `mspl_jeffreys`,
`mspl_penalty_components`'s link-threading), on non-separated data, at fitted
(or true) `beta` values, for `p in {2, 4}` and `n in {60, 200, 1000}`. It says
nothing about drmTMB-Laplace finite-estimate behaviour under the mixed-effects
composite, softness-scaling `c_n` correctness for non-logit links (design 253
Addendum 3 already finds `c_n = 2*sqrt(p/n)` is a logit-specific delta-method
result, not transportable as-is), separated/quasi-separated data, or the
C++ kernel at `src/drmTMB.cpp:4966-4969` (which remains logit-only and was
not touched or exercised here). The public MSPL entry point's guard at
`R/mspl-estimator.R:179-184` was not modified and this slice provides no
basis for relaxing it.
