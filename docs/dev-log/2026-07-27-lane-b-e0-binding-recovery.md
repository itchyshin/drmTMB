# Lane-B E0 binding-source recovery

**Scope:** internal campaign-readiness provenance only. This record changes no
capability-ledger row, public claim, default, association route, bootstrap
route, missing-response route, or compute state.

## Finding

The archived sources recover route/DGP provenance for two high-value batches,
but neither batch authorizes an interval campaign yet. The distinction is
intentional: a recovery DGP or a generic profile-target API test is not a
reviewed `cell × target` coverage contract.

| Batch | Candidate cells | Recovered source | What is recoverable | Still required before binding |
| --- | ---: | --- | --- | --- |
| Count q1 one-slope | `mc-0410`–`mc-0413`, `mc-0435`, `mc-0441`, `mc-0448`, `mc-0452` | `tools/slurm/count-slope-recovery-rorqual.sbatch`; `docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual/`; the eight `tools/run-structured-re-count-slope-*-local-micro-shard.R` runners | provider/family route, formula cell, 80 seeds `760001:760080`, source SHA receipts, and truth for fixed effects plus intercept and slope SDs | choose and review the exact profile estimand(s) per cell; recovery runners record estimates, not profile intervals |
| Bivariate REML fixed/q2/q4 | `mc-0182`–`mc-0185`, `mc-0208`–`mc-0209`, `mc-0212`–`mc-0219` | `tests/testthat/test-reml-bivariate.R`; `docs/design/221-native-reml-finish.md`; `R/profile.R` target construction | formulas, fixture truths, q2/q4 covariance construction, and direct target identities | select target cardinality for the fixed-effect routes and run a separate exact-DGP profile smoke; generic target tests explicitly permit `profile_failed` |

## Count-source boundary

The Rorqual sbatch records the exact eight provider/family shards and the
original seed block. Its copied replicate tables retain each seed, truth,
fit state, and `pdHess`, so their recovery provenance is stronger than a
ledger note. It remains recovery-only by its own contract: it never calls
`confint()`, has no interval endpoints, and labels its denominator
`not_coverage_evidence`. The one-slope DGPs contain *both* an intercept SD and
a slope SD. Therefore the archived `sd_mu_intercept` and `sd_mu_x` columns do
not license silently selecting either as the future profile target.

## REML-source boundary

The fixed bivariate fixture sets `beta1 = (0.3, 0.5)`, `beta2 = (0.1, 0.2)`,
residual SD1 `0.8`, and residual SD2 `0.9`; each fixed route can expose both
an intercept and an `x` profile target. The q2 and q4 fixtures identify their
structured axes, including the dense q4 adequate-power smoke. They establish
target names such as `sd:mu:mu1:phylo(1 | p | sp)` but not a completed profile
attempt for the exact REML campaign DGP. No source supports treating a finite
generic profile test as coverage evidence.

## Local technical smoke (route validation only)

On the then-current Lane-B readiness source, the recovered count fixture was
run locally at its archived first seed (`760001`) with the required named
`tree` object and exact q1 Poisson phylogeny formula
`poisson_phylo ~ x + phylo(1 + x | site, tree = tree)`. Both direct targets
were profile-ready and returned endpoint profiles: `sd:mu:phylo(1 | site)`
returned `[0, 0.4095412]`, and `sd:mu:phylo(0 + x | site)` returned
`[0, 0.3115247]` (both `conf.status = "profile"`). This is a local
formula/target-routing smoke only: one seed, no coverage denominator, no
historical-cell reclassification, no target-selection decision, and no remote
compute. It also caught and resolved the required grammar detail that the
marker must receive a named `tree` object rather than an inline `sim$tree`
expression.

## Binding rule carried forward

Only a canonical binding table may turn either recovery result into a schedule.
It must name an exact DGP function/version, formula, truth on its reporting
scale, one or more namespaced direct profile targets, information rung, and
source receipt. Any cell lacking all of those remains unavailable. K=12 keeps
its dedicated negative-control target and must remain incomplete/unavailable.

### Exact K=12 negative-control contract

The sole E0 K=12 control is `mc-0260m`, not any structured `q12` cell. Its
canonical source is `inst/sim/run/sim_run_meta_v_lss_smoke.R`:
`dense_k12_historical_failure_control`, layer `LSS`, `n_study = 12`, two
effects and two replications per study, dense known `V`, `sampling_rho = .25`,
and restored source seed `1592943833`. The target rows are
`sd:study:(Intercept)` / `fixef:sd(study):(Intercept)` and
`sd:study:z_study` / `fixef:sd(study):z_study`, with truth values supplied by
`phase18_meta_v_lss_targets()`. Both must be retained as negative-control
attempts: a finite `conf.status = "profile"` is an error, while
`nonfinite_interval`, `clamp_limited`, or `trace_incomplete` stays unavailable
and non-covering. This is a binding specification only; it does not authorize
or launch a pregrid.

### Recovered B1 ordinary-RE binding subset

Eight frozen E0 candidates have an existing **B1 cell × target** source
contract in `tools/b1-breadth-contract.R:10-57`: four ordinary REs and four
structured routes. They are legitimate
canonical-binding inputs, but only for route/DGP/target/rung definition: the
B1 worker checks `profile_targets()` readiness and does not provide profile
interval or coverage evidence.

| Cell | DGP ID | Exact profile target | Truth/reporting scale | Rungs |
| --- | --- | --- | --- | --- |
| `mc-0005` | `b1_beta_mu_intercept` | `sd:mu:(1 | id)` | 0.55, beta latent/link-scale mu SD | 24/48/96 groups; 10/group |
| `mc-0059` | `b1_binomial_mu_intercept` | `sd:mu:(1 | id)` | 0.80, binomial logit-scale mu SD | 24/48/96; 12/group |
| `mc-0270` | `b1_gaussian_sigma_slope` | `sd:sigma:(0 + w | id)` | 0.35, log-sigma slope SD | 24/48/96; 12/group |
| `mc-0511` | `b1_truncated_nbinom2_mu_slope` | `sd:mu:(0 + x | id)` | 0.48, log-mu latent slope SD | 24/48/96; 8/group |
| `mc-0251` | `arc3a_positive_continuous` | `sd:mu:phylo(1 | id)` | adapter-owned Gamma phylo mu SD | 24/48/96 adapter rungs |
| `mc-0388` | `arc3a_positive_continuous` | `sd:mu:relmat(1 | id)` | adapter-owned lognormal relmat mu SD | 24/48/96 adapter rungs |
| `mc-0423` | `new_nbinom2_sigma_animal` | `sd:sigma:animal(0 + x | id)` | adapter-owned NB2 log-sigma slope SD | 24/48/96 adapter rungs |
| `mc-0438` | `count_phylo_interaction` | `sd:mu:phylo_interaction(1 | plant:pollinator)` | adapter-owned Poisson phylo-interaction mu SD | 24/48/96 adapter rungs |

These are not a permission to schedule a partial pregrid: the full E0 cohort
still requires exact binding coverage, and each B1 target needs the planned
local profile smoke before it can participate in the no-compute packet.

The first fixed-seed local smoke has been run for the four ordinary in-cohort
B1 targets at their low-rung seed (`b1_seed(cell, low, 1)`). Every fit
converged with `pdHess = TRUE`, and every selected direct target returned
`conf.status = "profile"`:

| Cell | Seed | Profile interval |
| --- | ---: | --- |
| `mc-0005` | 2026072601 | `[0.2731837, 0.6211540]` |
| `mc-0059` | 2026073801 | `[0.4296265, 0.8129648]` |
| `mc-0270` | 2026076201 | `[0.3090095, 0.6343688]` |
| `mc-0511` | 2026080401 | `[0.3793644, 0.9316135]` |

This is a four-attempt route-validation receipt, not interval calibration: no
attempt was discarded, but it supplies neither an all-seed denominator nor a
coverage estimate and changes no capability status.

The four structured B1 intersection routes were then run the same way. All
four converged and returned `conf.status = "profile"`, but all four had
`pdHess = FALSE`; these are retained route-validation outcomes, not a basis to
relax the later campaign's all-attempt availability rule.

| Cell | Seed | Profile interval | `pdHess` |
| --- | ---: | --- | --- |
| `mc-0251` | 2026075601 | `[0.3000979, 0.5442037]` | `FALSE` |
| `mc-0388` | 2026077401 | `[0.3124686, 0.5310761]` | `FALSE` |
| `mc-0423` | 2026078001 | `[0, 0.3387393]` (`near_sd_boundary`) | `FALSE` |
| `mc-0438` | 2026078601 | `[0.1926422, 0.6244484]` | `FALSE` |

### Gaussian recovery boundary

Outside `mc-0270` and the documented meta-V negative control, no Gaussian
model-surface row currently has a complete recoverable contract. The q3 ML
Gaussian mu-slope DGP is a near miss for the REML `mc-0269` route, and the
remaining ordinary fixtures establish admission or point estimates but lack a
reusable exact-DGP/profile-rung source. All 31 Gaussian structured rows remain
unbound: their legacy q-series labels do not identify an exact historical
component or target. They must not be filled by heuristic provider/q matching.
