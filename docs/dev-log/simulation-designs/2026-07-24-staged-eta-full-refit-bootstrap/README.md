# Staged Bernoulli × NB2 full-refit bootstrap contract

**Status:** stopped developer-only pilot. The tiny local smoke is a schema
check only. The initially launched full grid was stopped before completion
because its cost was disproportionate to an uncommitted, non-public inference
feature. Its partial host outputs are preserved for provenance only and must
not be aggregated or used as feasibility, recovery, or calibration evidence.
No public interval API or capability claim is authorized by this contract.

## Symbolic alignment

| Symbol / target | Fixed-design DGP | Refit / extraction | Truth / interval target |
| --- | --- | --- | --- |
| \(x_i\) | equally spaced `[-1.4, 1.4]` | unchanged in every bootstrap data set | fixed observed design |
| \(p_i\) | `plogis(binary_intercept + 0.3*x)` | `binomial()` `mu ~ x` refit | fitted stage-1 Bernoulli margin |
| \(\mu_i\) | `exp(0.7 + 0.2*x)` | `nbinom2()` `mu ~ x, sigma ~ 1` refit | fitted stage-1 NB2 mean |
| \(\sigma_i\) | `0.25` or `0.65` | `nbinom2()` `sigma ~ 1` refit | fitted stage-1 NB2 dispersion; `size = sigma^-2` |
| \(\alpha_0,\alpha_1\) | `(0,0)` or `(-0.15,0.65)` | `associate_pairs(..., association = ~x)` after both margin refits | percentile link-coefficient intervals |
| \(\eta(x)\) | `0.999999*tanh(alpha0 + alpha1*x)` | transform each resolved coefficient draw | percentile intervals only at `x=-1,0,1` |

The independent test oracle constructs `size = sigma^-2`, tail probabilities,
and the NB2 inverse without calling the production quantile helper. The existing
`mvtnorm::pmvnorm()` rectangle oracle remains the kernel oracle.

## Immutable execution policy

- 24 cells: `n = 120, 240, 480` × two Bernoulli intercepts × two NB2
  dispersions × two association vectors.
- 200 **all-attempt** outer data sets per cell; failures remain in the outer
  denominator.
- 399 full-refit bootstrap attempts per outer data set; each resimulates both
  responses, refits both margins, and refits `eta`.
- An interval needs at least 380 resolved association fits. Unavailable
  intervals are non-covering for all-attempt coverage; conditional coverage is
  reported separately.
- Every stage-1/stage-2 status, message, score/curvature/multistart,
  integration/endpoint diagnostic, seed, and response-pattern diagnostic is
  retained in the CSV/RDS ledgers.

The driver is [sim_run_staged_eta_bernoulli_nbinom2_bootstrap.R](../../../../inst/sim/run/sim_run_staged_eta_bernoulli_nbinom2_bootstrap.R).
It stops unless `RUN_STAGED_ETA_BOOTSTRAP=true`, which may be set only after a
fresh approved smoke. The full grid is DRAC work, never GitHub Actions.

With a separately approved local smoke, set `SMOKE=true`. That executes only
regular slope cell `staged_eta_17`, two outer attempts, and five full-refit
bootstrap attempts per outer fit. It is a non-empty-output and ledger-schema
check, not recovery, interval availability, or coverage evidence.

## DRAC shard contract

The former campaign design uses array indices `1:4800`, where index `k` maps
deterministically to `cell = ceiling(k / 200)` and
`outer = ((k - 1) %% 200) + 1`. Each task runs all 399 bootstrap refits for
exactly one outer data set and writes its own immutable CSV/RDS ledger under
`results/staged_eta_XX/outer_YYY/`. This keeps failed or interrupted tasks
visible and rerunnable without changing the 200-all-attempt denominator.

The dormant worker is
[staged-eta-full-refit-bootstrap-fir.sbatch](../../../../tools/slurm/staged-eta-full-refit-bootstrap-fir.sbatch).
It requires a prepared isolated R library containing the exact source snapshot,
sets `R_PROFILE_USER=/dev/null`, and refuses login-node execution. A future
aggregation step must require exactly 200 outer ledgers per cell and preserve
every missing ledger as an all-attempt failure; it must not silently recover or
drop them. The fail-closed aggregator is
[summarize-staged-eta-full-refit-bootstrap.R](../../../../tools/summarize-staged-eta-full-refit-bootstrap.R).
