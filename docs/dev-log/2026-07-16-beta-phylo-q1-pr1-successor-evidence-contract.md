# Beta phylogenetic q1 PR 1: successor evidence contract

## Status and authority

Shinichi restarted the approved two-PR Beta phylogenetic location-scale-scale
goal on 2026-07-16 after reviewing the stopped PR 1 evidence. This document is
a prospective successor to the stopped contract; it does not alter, rescore,
pool, or erase any earlier result. It must be committed with the diagnostic
harness, frozen seed designs, and tests before the first new fit.

PR 1 still concerns only univariate ML `beta()` with one unlabelled,
intercept-only `phylo(1 | spp_id, tree = tree)` term on `mu`, fixed-effect-only
family `sigma`, and one constant latent phylogenetic location-effect SD. Here
family `sigma` means `phi = sigma^(-2)`. It is not the latent SD `tau`, and it
is not the future direct target of `sd(spp_id, level = "phylogenetic")` in PR 2.

The maximum possible PR 1 claim remains `point_fit_recovery`. PR 2 may not be
implemented or run until PR 1 has separate review, merge, and exact post-merge
CI evidence.

## Immutable prior evidence

The following results remain visible practical-boundary evidence:

| Design | Mean log-`tau` bias | Frozen verdict |
| --- | ---: | --- |
| `m = 2`, `g = 256`, 400 attempts | `-0.5203` | HOLD |
| `m = 4`, `g = 256`, 400 attempts | `-0.2470` | HOLD |
| disjoint `m = 4`, `g = 256`, 10-attempt abort pilot | `-0.2214` (MCSE `0.0861`) | HOLD |
| `m = 2`, `g = 1024`, 400 attempts | `-0.0888` | PASS in that cell |
| `m = 4`, `g = 1024`, 400 attempts | `-0.0618` | PASS in that cell |
| disjoint `m = 4`, `g = 1024`, 10-attempt abort pilot | `-0.0771` | PASS in that cell |

The earlier `m = 4` campaign is valid for its own estimand but is not an
independent replication of the `m = 2` campaign because 1,197/1,200 numeric
DGP seeds overlap. None of these results may be pooled with the successor
campaign or used as prospective promotion evidence.

## ADEMP question

### Aims

1. Diagnose whether first-order Laplace error materially shifts the estimated
   log latent SD at the practically concerning `m = 4`, `g = 256` boundary.
2. Independently test point recovery at two higher-information cells selected
   from the observed N pattern, without claiming a universal minimum species
   count.

The diagnostic addresses mechanism only. The recovery campaign addresses the
bounded product claim. Neither can substitute for the other.

### Data-generating mechanism

The DGP remains exactly `beta_phylo_dgp()` in
`tools/run-beta-phylo-q1-recovery.R`: a fresh coalescent tree per attempt;
unit-diagonal phylogenetic tip covariance; latent location field
`u ~ N(0, tau^2 A)`; `tau = 0.30`; `m = 4` observations per tip; standardized
Gaussian `x`; `logit(mu) = 0 + 0.35 x + u`; and
`log(sigma) = log(0.25) + 0.20 x`, so `phi = sigma^(-2)`. RNG kind is frozen to
`Mersenne-Twister/Inversion/Rejection` for the complete DGP and restored after
each attempt.

### Estimands

The primary recovery estimand is mean error in `log(tau)`. Secondary estimands
are mean errors for the two `mu` coefficients and two family-`sigma`
coefficients, plus their RMSEs. Raw `tau`, medians, and boundary-excluded
summaries are descriptive only and cannot change a verdict.

For the diagnostic, the estimand is the paired shift

`Delta = corrected log(tau) - Laplace log(tau)`

on a fixed dataset. It is not a recovery result.

### Methods

The fitted estimator remains drmTMB ML with first-order Laplace integration and
the frozen robust optimizer. The diagnostic uses TMB's existing
Gaussian-proposal importance sampler on the same full correlated joint
objective. It does not change the package estimator or add an API.

### Factors and attempted replicates

- Diagnostic screen D0: the first five `g = 256`, `m = 4` rows, by replicate
  order, from the previously frozen but unrun disjoint-repair certification
  design. Their numeric seeds are `1834980414`, `348679578`, `1028561677`,
  `2023711313`, and `2093308563`. Selection is deterministic and outcome-blind.
- Diagnostic confirmation D1: the first 24 rows from that same `g = 256`,
  `m = 4` block. D0 is a subset of D1. D1 runs only if D0 weight and stability
  gates pass. The frozen 24-row design SHA-256 is
  `fefc3ca7cd143f946cbd68d2a99ddfab56ad2acb5001659911d393bb6dbdce6f`.
- Prospective recovery H1: `g = 512`, `m = 4`, 400 attempted fits.
- Prospective recovery H2: `g = 1024`, `m = 4`, 400 attempted fits.

The H1/H2 seed table must contain 800 unique numeric seeds drawn without
replacement from `.Machine$integer.max` under master seed `2026071641`. It
must have zero overlap with every earlier original, addendum, smoke, pilot, and
repair design. The exact table and its SHA-256 are frozen before smoke.
Its frozen SHA-256 is
`73685aed37eda78f7a5fb86cb90e0d6974a54fb1055d11214bdea8b316415b9f`.
The separate two-fit smoke uses master seed `2026071640` and has zero overlap
with both the certification and all prior designs.

Four hundred attempts target a Monte Carlo SE near `0.01` for the H2 log-SD
bias, based on the earlier `m = 4`, `g = 1024` SD of errors (`0.1897`). This is
adequate for the predeclared equivalence interval when the true bias is near
the earlier `-0.0618`; it is not a power calculation for a universal domain.

## Diagnostic algorithm and fail-closed gates

At the converged Laplace optimum for each fixed dataset, the harness must pin
the full conditional mode and call `fit$obj$env$MC()` with antithetic Gaussian
proposal draws. The D0 proposal ladder is `n = 2048`, `8192`, and `32768`, where
TMB evaluates `2n` draws after antithetic pairing. The maximum rung is repeated
with two independent batches. For diagnostic replicate `r`, batch A uses
`2026071650 + 100*r + {1,2,3}` across the three rungs and maximum-rung batch B
uses `2026072650 + 100*r + 3`. The harness must retain
the negative log importance ratios, normalized-weight ESS, maximum normalized
weight, corrected fixed-parameter score, Laplace fixed Hessian, and implied
one-step multivariate shift. The fixed-parameter Hessian is obtained with
`optimHess()` on the marginal Laplace objective, then the conditional mode is
repinned before importance sampling. The antithetic pair, rather than each of
its two dependent draws, is the independent unit for the weight ESS.

D0 passes only if, for every dataset and both maximum-rung batches:

1. all target evaluations and corrected-score elements are finite;
2. normalized-weight ESS is at least 1,000;
3. the maximum normalized weight is at most `0.01`;
4. the two batches' implied log-`tau` shifts differ by at most `0.05`; and
5. increasing `n` does not reverse the sign of the implied shift at the two
   largest rungs. Every source fit must also have convergence code zero,
   `pdHess = TRUE`, a positive-definite marginal fixed Hessian, and Hessian
   condition number at most `1e10`.

Failure of an ESS, weight, or stability gate is `INCONCLUSIVE`. It is not
evidence that Laplace is accurate. No ad hoc proposal tuning is allowed under
this contract.

If D0 passes under the same Git head, D1 jointly reoptimizes all five fixed
parameters under each of two independent importance-corrected objectives.
Each batch uses `n = 8192` antithetic pairs with common random numbers across
optimizer evaluations. Each batch freezes the full Gaussian importance
proposal at the original Laplace optimum. Candidate evaluations replace only
the fixed-parameter entries of the target vector; the proposal centre,
proposal Hessian, transformed draws, and `par0` remain fixed. This makes the
TMB corrected score the derivative of the finite-sample corrected objective.
For diagnostic replicate `r`, batch A uses seed
`2026073650 + 100*r` and batch B uses `2026074650 + 100*r`. Both start from the
same Laplace optimum. `nlminb()` uses the TMB importance-corrected objective and
score with `eval.max = 100`, `iter.max = 50`, and `rel.tol = 1e-8`; only
log-`tau` is bounded, at the Laplace estimate plus or minus `0.60`.

Each corrected refit must have optimizer convergence code zero, pair-level ESS
at least 1,000, maximum normalized pair weight at most `0.01`, maximum absolute
corrected score at most `0.05`, and distance at least `0.05` from either
log-`tau` bound. The two corrected log-`tau` estimates must agree within
`0.03`; their mean is the corrected estimate. A failed optimizer, weight,
score, boundary, or batch-agreement condition is `INCONCLUSIVE`.

Across the 24 paired datasets:

- **Laplace materially implicated:** the 95% t interval for mean `Delta` lies
  wholly above `+0.10`. Stop PR 1 before opening it and propose a separate
  estimator-method goal.
- **Laplace shift equivalent; residual ML bias remains:** the 95% t interval
  for mean `Delta` lies wholly within `[-0.05, +0.05]` and the upper 95% t bound
  for corrected mean log-`tau` recovery bias is below `-0.10`. This supports
  continuing the N-ladder without an estimator arc; it does not prove a
  universal finite-information mechanism.
- **Mixed or inconclusive:** every other result, including a failed weight or
  corrected-refit stability gate. Do not make a causal claim about the
  mechanism.

D1 is diagnostic-only. Its 24 datasets are never pooled with H1/H2 and cannot
promote a ledger row. It writes both corrected refits, one paired optimum row
per dataset, and one aggregate decision row. A production estimator arc is
opened only for the predeclared `Laplace materially implicated` result.

## Prospective recovery gates

Every one of the 800 H1/H2 attempts is retained in the denominator. No fit may
be excluded for convergence, Hessian, gradient, warning, or boundary status.
Each cell must satisfy:

1. convergence-code-zero rate at least `0.95`;
2. `pdHess = TRUE` rate at least `0.95`;
3. absolute mean bias at most `0.10` for all four fixed coefficients;
4. the 95% normal Monte Carlo interval for mean log-`tau` error lies wholly
   inside `[-0.10, +0.10]`; and
5. all five estimates are finite for every attempted fit. Finite estimates from
   nonzero-convergence fits remain in the recovery summaries; convergence is a
   separate all-attempt quality gate.

RMSE and its 95% bootstrap difference interval are descriptive only because a
one-standard-error veto has an unacceptably high false-HOLD rate across five
targets. The bootstrap uses 2,000 resamples and seed
`2026071695 + parameter_index`.

Decision algebra:

- H1 PASS and H2 PASS: PR 1 may claim recovery only in the exact two tested
  high-information regimes.
- H1 HOLD and H2 PASS: PR 1 may claim recovery only in the exact
  `g = 1024`, `m = 4` regime; H1 and every earlier HOLD stay prominent.
- H2 HOLD: no PR 1 and no PR 2.
- A material diagnostic Laplace discrepancy: stop before PR 1 regardless of
  H1/H2 and seek a separately approved estimator-method goal.
- An inconclusive diagnostic does not fail H1/H2, but the mechanism must remain
  explicitly unresolved in the PR and ledger wording.

No result authorizes wording such as `g >= 512`, `g >= 1024`, or a universally
adequate sample size. Information also depends on within-tip replication, tree
shape, latent effect size, family precision, and covariates.

## Outputs, provenance, and authentication

Before a fit, the runner must authenticate clean and tracked protected paths;
the exact `R` and `src` Git trees; all three runner blobs; the contract, tests,
and both frozen designs; the SHA-256 of every prior seed-audit input; TMB
1.9.21; the frozen RNG kind; Totoro or an active SLURM allocation on a named
DRAC cluster; absence of GitHub Actions; and `OPENBLAS_NUM_THREADS=1`. A DRAC
login node without `SLURM_JOB_ID` is rejected. The runner writes this passing preflight manifest,
the complete design, the seed audit, and `PRE_DISPATCH` provenance before
dispatch.

Each completed attempt or diagnostic dataset is written as an atomic shard.
Aggregation requires the exact duplicate-free design keys. An interrupted run
therefore preserves completed work; it may resume only with an explicit
`--resume` and strictly value-equivalent design and preflight manifest. It must retain
raw attempts, summaries, gates, weight diagnostics, corrected refits,
seed audits, manifests, session information, and final `COMPLETE` provenance.

Campaign compute runs on Totoro (at most 96 workers, with
`OPENBLAS_NUM_THREADS=1`) or DRAC, never GitHub Actions. Artifacts remain local
and only compact evidence required for review is committed.

## Claim boundary if PR 1 passes

The ledger and PR must say, in substance:

> Implemented and verified at `point_fit_recovery` only for univariate ML
> `beta()`, one unlabelled q1 intercept-only `phylo()` location effect,
> fixed-effects-only family `sigma`, and constant latent phylogenetic SD, under
> the exact predeclared high-information simulation cells that passed.
> Moderate-information `g = 256` designs failed mean log-SD recovery. No
> minimum universally adequate species count is established.

No intervals, coverage, `inference_ready`, REML, q2/q4, labels, phylogenetic
slopes, phylogenetic family-`sigma`, direct `sd()` regression, hierarchical
`sd()` RHS, `zero_one_beta()`, missing-data, external-data, or all-family claim
is included.
