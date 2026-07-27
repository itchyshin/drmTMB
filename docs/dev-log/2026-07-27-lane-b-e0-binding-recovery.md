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
| Bivariate ML q2 slope | `mc-0109`–`mc-0110`, `mc-0131`–`mc-0132` | `inst/sim/R/sim_structured_re_bridge_fixtures.R:phase18_structured_re_q2_slope_payload_fixture` | exact provider/formula grammar and deterministic target names | unavailable: the source is `fixture_only` and explicitly records `profile grid not run`; do not borrow its old Wald/fixture evidence as a profile binding |

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

## ML q2 slope boundary

The archived q2 slope payloads are useful negative provenance, not omitted
smokes. For the spatial and animal location pairs still in the frozen cohort,
the payload contract declares `fit_status = "fixture_only"` and its profile
channel as `not_evaluated` with the literal reason `profile grid not run`.
This is weaker than a local exact-DGP profile smoke and therefore does not
satisfy the binding rule. Their earlier Wald/fixture parity results remain
descriptive evidence only; neither is a substitute profile channel, an
exclusion from an all-attempt denominator, or an authorization to retry away
the missing direct-profile route.

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

Machine-readable local attempts now live in
[`interval-campaign-bindings/2026-07-27-b1-local-smoke-receipts.tsv`](interval-campaign-bindings/2026-07-27-b1-local-smoke-receipts.tsv).
The checked schema retains successful and failed profile attempts together:
finite non-boundary profiles carry endpoints; every other status carries a
named failure reason and no fabricated endpoints.

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

Both K=12 targets are now explicit rows in the checked partial binding table,
with link-scale truths `-1.00` and `0.20`. They are the only partial-table rows
whose future bound contracts carry `negative_control = TRUE`.

### Recovered B1 ordinary-RE binding subset

Eight frozen E0 candidates have an existing **B1 cell × target** source
contract in `tools/b1-breadth-contract.R:10-57`: four ordinary REs and four
structured routes. They are legitimate
canonical-binding inputs, but only for route/DGP/target/rung definition: the
B1 worker checks `profile_targets()` readiness and does not provide profile
interval or coverage evidence.

The recovered rows are stored in the checked partial table
[`interval-campaign-bindings/2026-07-27-b1-recovered-subset.tsv`](interval-campaign-bindings/2026-07-27-b1-recovered-subset.tsv).
The readiness helper validates its schema and cohort membership, but refuses to
turn it into a schedule because it deliberately lacks the other 148 cells.

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

### Recovered fixed-REML residual-scale subset

The bivariate fixed-REML fixture provides two more exact, direct targets:
`mc-0184` / `sigma1` (truth 0.80) and `mc-0185` / `sigma2` (truth 0.90), at
`n = 150`, seed 3. A local profile routing smoke returned response-scale
intervals `[0.7688046, 0.9658607]` and `[0.8450240, 1.0616163]`, respectively,
both with `conf.status = "profile"`. The fixed mean cells `mc-0182` and
`mc-0183` remain unbound: under this REML route their `mu1`/`mu2` coefficients
are marginalised and `profile_targets()` reports `missing_tmb_parameter`.
The partial table now has ten rows; these are still routing smokes, not
coverage evidence or a schedule.

### Recovered matched-q2 phylogenetic REML subset

The matched q2 phylogenetic REML fixture supplies direct structured targets for
`mc-0208` / `sd:mu:mu1:phylo(1 | p | sp)` (truth 1.00) and `mc-0209` /
`sd:mu:mu2:phylo(1 | p | sp)` (truth 0.80), at `n_tip = 150`, seed 4. Local
profiles returned `[0.7815568, 1.6685350]` and `[0.4983490, 1.2947650]`, both
with `conf.status = "profile"`. They add two direct target rows to the partial
table (14 total after the explicit K=12 pair); again this is technical routing
evidence, not coverage.

### Block-diagonal q4 REML target boundary

The exact block-diagonal q4 fixture confirms direct, profile-ready mean-side
targets for `mc-0212` / `sd:mu:mu1:phylo(1 | p | sp)` and `mc-0213` /
`sd:mu:mu2:phylo(1 | p | sp)`. At `n_tip = 100`, five observations per tip,
and seed 3, their local profiles returned `[0.5219659, 1.1660620]` and
`[0.2863490, 0.7168340]`, respectively, with direct/ready target metadata and
`conf.status = "profile"`. The truth is 0.60 and 0.50 on the response scale.
They therefore add two exact mean-side routing bindings (16 recovered target
rows, including the two K=12 control targets). This is still one local routing
smoke, not campaign coverage evidence. It does **not** expose the corresponding
scale-side terms for `mc-0214` or `mc-0215` as confidence-interval targets:
attempting `sd:sigma:sigma1:phylo(1 | ps | sp)` and its sigma2 analogue
returns `Unknown confidence-interval targets`. Those two cells therefore stay
unbound; no scale-side target was fabricated from the formula or summary.

### Recovered Poisson phylogenetic q1 slope

The archived `count_slope_phylo_poisson_q1_mu_one_slope` runner gives the exact
`mc-0435` DGP: a balanced eight-tip tree, 20 observations per tip, seed
`760001`, Poisson log-mean `0.55 - 0.15 x`, independent phylogenetic intercept
and slope SDs of 0.25 and 0.45, and
`phylo(1 + x | site, tree = tree)`. The direct slope target is
`sd:mu:phylo(0 + x | site)`. A local exact-DGP profile smoke returned
`[0, 0.2509684]`, `conf.status = "profile"`, and `near_sd_boundary` with
`pdHess = TRUE`. This is an exact routing binding, but the boundary contact is
retained as negative technical evidence: it does not count as a finite-profile
success, coverage result, or permission to relax later all-attempt rules.

### Recovered NB2 phylogenetic q1 slope

The parallel `count_slope_phylo_nbinom2_q1_mu_one_slope` runner supplies the
exact `mc-0410` DGP: the same eight-tip/20-per-tip design and seed `760001`,
with NB2 `sigma = 0.55`, and the same log-mu coefficients and phylogenetic SD
truths (0.25 intercept, 0.45 slope). Its direct target is likewise
`sd:mu:phylo(0 + x | site)`. The local exact-DGP smoke returned
`[0, 0.3120354]`, `conf.status = "profile"`, `near_sd_boundary`, and
`pdHess = TRUE`. It is bound as an exact routing target, while retaining the
boundary contact as non-covering technical evidence.

### Recovered Poisson q1 spatial, animal, and relatedness slopes

The three parallel archived Poisson runners recover exact DGPs for `mc-0441`
(spatial), `mc-0448` (animal), and `mc-0452` (relatedness): eight grouping
levels, 20 observations per level, seed `760001`, log-mu `0.55 - 0.15 x`, and
independent intercept/slope SD truths 0.25/0.45. Their direct slope targets
are, respectively, `sd:mu:spatial(0 + x | site)`,
`sd:mu:animal(0 + x | id)`, and `sd:mu:relmat(0 + x | id)`. Exact-DGP local
profile smokes returned `[0, 0.3056272]`, `[0, 0.2791434]`, and
`[0, 0.2791434]`; every target was direct/ready, fit with convergence 0 and
`pdHess = TRUE`, and returned `near_sd_boundary`. All three are therefore
bound for route identity while their lower-bound contact remains negative,
non-covering technical evidence.

### Recovered NB2 q1 spatial, animal, and relatedness slopes

The NB2 companion runners provide exact contracts for `mc-0411` (spatial),
`mc-0412` (animal), and `mc-0413` (relatedness): the same eight-level,
20-per-level, seed-`760001` structure and log-mu/SD truths as their Poisson
counterparts, plus fixed NB2 `sigma = 0.55`. Their direct slope targets are
`sd:mu:spatial(0 + x | site)`, `sd:mu:animal(0 + x | id)`, and
`sd:mu:relmat(0 + x | id)`. Exact-DGP local profiles were respectively
`[0, 0.3236126]`, `[0, 0.3634323]`, and `[0, 0.3634323]`; each was direct and
ready, converged with `pdHess = TRUE`, and reported `near_sd_boundary`.
They are exact routing bindings only. Their boundary contact is retained as
non-covering technical evidence.

### Recovered Beta ordinary mu slope

The exact `mc-0007` fixture has 26 groups of eight observations, seed
`20260532`, Beta precision 34, a latent logit-mu linear predictor
`0.15 + 0.42 x`, and an independent `(0 + x | id)` slope SD of 0.48. Its
direct target `sd:mu:(0 + x | id)` was profile-ready and the local profile
smoke returned `[0.3578016, 0.6567327]`, `conf.status = "profile"`,
convergence 0, and `pdHess = TRUE`. This is a routing binding only, not
coverage evidence.

### Recovered lognormal ordinary mu slope

The cross-family fixture also gives `mc-0380` an exact DGP: 26 groups of
eight observations, seed `20260530`, lognormal residual log-SD 0.28, and
link-scale mu slope SD 0.48 in `(0 + x | id)`. Its direct profile target is
`sd:mu:(0 + x | id)`. The local profile returned `[0.3439994, 0.6179252]`,
`conf.status = "profile"`, convergence 0, and `pdHess = TRUE`. It is an exact
routing binding only, not coverage evidence.

### Recovered Poisson and NB2 ordinary mu slopes

The Poisson `mc-0431` fixture has 42 groups of 11 observations, seed
`20260621`, and an independent log-mu slope SD of 0.45. Its direct profile
returned `[0.1932162, 0.4389299]`, with `conf.status = "profile"`, convergence
0, and `pdHess = TRUE`. The NB2 `mc-0402` fixture has 44 groups of 10,
seed `20260628`, fixed-effect log-sigma `-0.70 + 0.20 z`, an independent
mu intercept SD 0.45, and the direct mu slope-SD truth 0.30. Its direct
profile returned `[0.1686393, 0.4514289]`, again with `conf.status = "profile"`,
convergence 0, and `pdHess = TRUE`. Both are exact routing bindings only;
neither is coverage evidence.

### Recovered Poisson ordinary mu intercept

The `mc-0429` source fixture is an exact 36-group, 10-observation-per-group
Poisson log-mu intercept DGP (seed `20260619`, true SD 0.55). Its direct
`sd:mu:(1 | id)` profile returned `[0.4791987, 0.8371075]` with
`conf.status = "profile"`, convergence 0, and `pdHess = TRUE`. This is an
exact routing binding only, not coverage evidence.

### Recovered Arc-2a ordinary mu intercepts

Three exact Arc-2a fixtures add direct interior profile routes. `mc-0463`
(skew-normal, 40 groups × 14, seed `20260712`, true location SD 0.70) returned
`[0.5091854, 0.8209202]`; `mc-0567` (zero-one-beta, 45 × 16, seed 7, true
latent-logit SD 0.60) returned `[0.4644101, 0.7520640]`; and `mc-0225`
(cumulative logit, 45 × 18, seed 9, true latent-logit SD 0.70) returned
`[0.4972216, 0.9334606]`. Each target is `sd:mu:(1 | id)`, direct and
profile-ready, with `conf.status = "profile"`, convergence 0, and
`pdHess = TRUE`. These are routing bindings only, not coverage evidence.

### Recovered Tweedie ordinary mu intercept

The exact `mc-0538` fixture has 40 groups of 12 observations, seed
`20260712`, Tweedie power 1.5 and dispersion 0.6, and a log-mu intercept SD
truth of 0.50. Its direct `sd:mu:(1 | id)` profile returned
`[0.4887596, 0.8098379]`, `conf.status = "profile"`, convergence 0, and
`pdHess = TRUE`. This is an exact routing binding only, not coverage evidence.

### Recovered NB2 ordinary mu and sigma intercepts

The exact NB2 fixtures give direct profiles for `mc-0401` and `mc-0403`.
The 44-group × 10, seed-`20260628` mu intercept-and-slope DGP has mu intercept
SD truth 0.45; `sd:mu:(1 | id)` returned `[0.3494237, 0.6718856]`. The 42 × 20,
seed-`20260642` sigma-intercept DGP has log-sigma SD truth 0.42;
`sd:sigma:(1 | id)` returned `[0.3086365, 0.6247901]`. Both were direct,
profile-ready and returned `conf.status = "profile"` with convergence 0 and
`pdHess = TRUE`. They are routing bindings only, not coverage evidence.

### Recovered Gaussian sigma random slope

The self-describing Phase-18 Gaussian `mc-0271` DGP fixes 32 groups × eight
observations, seed 238, and true log-sigma slope SD 0.34 in `(0 + w | id)`.
The direct `sd:sigma:(0 + w | id)` profile returned `[0.2850093, 0.7264350]`,
`conf.status = "profile"`, convergence 0, and `pdHess = TRUE`. The DGP required
the declared Phase-18 registry helper when sourced locally; after loading it,
the smoke was reproducible. This is an exact routing binding only, not coverage
evidence.

### Recovered Gaussian REML ordinary intercepts

Two exact Gaussian REML fixtures add direct targets. The `mc-0265` bias-study
condition (18 groups × four, seed 1001, mu SD truth 0.80) yielded an interior
`sd:mu:(1 | id)` profile `[0.5316308, 1.1104370]`. The `mc-0267`
ordinary-sigma fixture (40 × eight, seed 1, log-sigma SD truth 0.40) yielded
`sd:sigma:(1 | id)` `[0.1526102, 0.4156606]`. Both targets were direct/ready,
with `conf.status = "profile"`, convergence 0, and `pdHess = TRUE`. These are
local routing bindings, not coverage evidence.

### Recovered Arc 1b-S1 bivariate spatial q2 REML intercepts

The self-describing Arc 1b-S1 spatial-q2 DGP exactly matches the two admitted
matched-location cells: `mc-0199` / `sd:mu:mu1:spatial(1 | p | site)` and
`mc-0672` / `sd:mu:mu2:spatial(1 | p | site)`. It fixes the labelled spatial
block in both mean endpoints, keeps `sigma1`, `sigma2`, and `rho12` intercept
only, and uses `biv_gaussian(REML)`. At 24 sites × six observations, ring
geometry, and seed `20260727`, the direct profiles returned `[0.3679984,
0.7172404]` for the mu1 truth 0.50 and `[0.3385775, 0.6624328]` for the mu2
truth 0.42; convergence was zero and both targets were profile-ready. This is
an exact local routing binding only, not interval calibration or coverage
evidence.

### Recovered Arc 1b-S2R bivariate relatedness q2 REML intercepts

The self-describing relatedness-q2 DGP supplies the matching labelled
`relmat(1 | p | id, K = K)` location block in both mean endpoints for the two
Arc 1b-S2R cells: `mc-0201` / `sd:mu:mu1:relmat(1 | p | id)` and `mc-0674` /
`sd:mu:mu2:relmat(1 | p | id)`. At 24 levels × six observations, covariance
`K`, and seed `20260727`, the `biv_gaussian(REML)` profiles returned
`[0.5050604, 0.9164290]` for the mu1 truth 0.60 and `[0.4078618, 0.7430743]`
for the mu2 truth 0.50. Both were direct/profile-ready, converged with code
zero, and had non-boundary profile endpoints. This is a local routing binding
only, not interval calibration or coverage evidence.

### Recovered ML bivariate spatial q2 intercepts

The same spatial-q2 source independently provides the ML q2 location pair
`mc-0107` / `sd:mu:mu1:spatial(1 | p | site)` and `mc-0108` /
`sd:mu:mu2:spatial(1 | p | site)`. It is a separate estimator stratum from
the Arc 1b-S1 REML pair. At the declared 24 sites × six ring fixture and seed
`20260727`, ML profiles returned `[0.3591473, 0.6930703]` for the mu1 truth
0.50 and `[0.3303320, 0.6396797]` for the mu2 truth 0.42, each with convergence
zero and non-boundary `conf.status = "profile"`. These are local routing
bindings only, not interval calibration or coverage evidence.

### Recovered ML bivariate relatedness q2 intercepts

The matching ML relatedness q2 pair is `mc-0151` /
`sd:mu:mu1:relmat(1 | p | id)` and `mc-0152` /
`sd:mu:mu2:relmat(1 | p | id)`. The self-describing DGP fixes the common
labelled `K` block in both mean endpoints. At 24 levels × six observations
and seed `20260727`, profiles returned `[0.4965167, 0.8899039]` for the mu1
truth 0.60 and `[0.4008383, 0.7214585]` for the mu2 truth 0.50. Both direct
targets had convergence zero and non-boundary `conf.status = "profile"`.
They are local routing bindings only, not interval calibration or coverage
evidence.

### Recovered ML bivariate animal q2 intercepts

The animal counterpart binds `mc-0129` /
`sd:mu:mu1:animal(1 | p | id)` and `mc-0130` /
`sd:mu:mu2:animal(1 | p | id)` to the exact shared known-matrix q2 DGP. With
`A = K`, 24 levels × six observations, and seed `20260727`, direct profiles
were `[0.4965167, 0.8899039]` around the mu1 truth 0.60 and
`[0.4008383, 0.7214585]` around the mu2 truth 0.50. Both profiles were finite,
non-boundary, and converged with code zero. They are local routing bindings
only, not interval calibration or coverage evidence.

### Recovered ML bivariate phylogenetic q2 intercepts

The ML phylogenetic q2 pair uses the exact archived fixture behind `mc-0083` /
`sd:mu:mu1:phylo(1 | p | sp)` and `mc-0084` /
`sd:mu:mu2:phylo(1 | p | sp)`: 150 tips, seed 4, and true SDs 1.00 and 0.80.
The independent ML profiles returned `[0.7520582, 1.6009320]` and
`[0.4748516, 1.1950660]`, respectively, with convergence zero and
non-boundary `conf.status = "profile"`. These remain routing bindings only,
not interval calibration or coverage evidence.

### Recovered Arc 3a lognormal phylogenetic q1 intercept

The exact Arc 3a generator defines the balanced-tree `lognormal()` route for
`mc-0386`: true log-location phylogenetic SD 0.50, fixed log-sigma 0.35, and
`y ~ x + phylo(1 | id, tree = tree)`. At its M32 × 20 local technical fixture
and seed `20260727`, the direct profile was `[0.3611700, 0.6194050]`, with
convergence zero and non-boundary `conf.status = "profile"`. This is an exact
local routing binding only, not the prior Arc 3a recovery result, a coverage
claim, or a promotion.

### Recovered Arc 3a Gamma relatedness q1 intercept

The same Arc 3a generator supplies the established Gamma–relatedness
comparator for `mc-0248`: `y ~ x + relmat(1 | id, K = K)`, true log-mu SD
0.50, and fixed sigma 0.35. At M32 × 20 and seed `20260727`, its direct
profile returned `[0.3980353, 0.6642229]`, converged with code zero, and had
a non-boundary `conf.status = "profile"`. This is a local routing binding
only; it does not alter the Arc 3a recovery evidence or establish coverage.

### Recovered Beta animal q1 mu intercept

The archived beta-animal fixture sets eight pedigree levels × ten observations,
seed `2026070401`, and latent/logit-mu animal SD truth 0.35. Its exact
`sd:mu:animal(1 | id)` profile returned `[0.2371351, 0.7135851]` with
convergence zero and non-boundary `conf.status = "profile"`. It is retained as
a single local routing binding, not coverage evidence and not a broader beta
animal claim.

### Beta animal q1 sigma intercept: retained local negative evidence

The distinct scale-side cell `mc-0015` was exercised on its archived fixture:
eight pedigree levels × 16 observations, seed `2026070404`, true log-sigma
animal SD 0.18, and `sigma ~ animal(1 | id, pedigree = ped)`. The target
`sd:sigma:animal(1 | id)` was direct/profile-ready and the fit converged, but
the profile ended `conf.status = "profile_failed"` with
`profile.message = "nonfinite_interval"` and a boundary flag. It remains
unbound and unavailable in any future all-attempt denominator; it is not
dropped, reclassified as a finite profile, or rescued by a Wald interval.

### Beta animal q1 mu slope: retained local negative evidence

The independent one-slope `mc-0013` fixture has eight pedigree levels × 20
observations, seed `2026070603`, with separate true intercept and slope SDs
0.30 and 0.20. Its slope target `sd:mu:animal(0 + x | id)` was
direct/profile-ready and the fit converged, but the direct profile returned
`profile_failed / nonfinite_interval` with a boundary flag. The failed slope
profile stays unavailable and non-covering; it does not inherit the successful
intercept's route binding.

### Recovered Poisson phylogenetic q1 intercept

The exact `mc-0434` fixture supplies a balanced 16-tip phylogeny, 18
observations per tip, seed `20260641`, and phylogenetic log-mu intercept SD
truth 0.55. Its direct `sd:mu:phylo(1 | species)` profile returned
`[0.1586605, 0.5865768]`, `conf.status = "profile"`, convergence 0, and
`pdHess = TRUE`. Formula construction requires binding the fixture tree to a
named `tree` object, which is now recorded as part of the exact route. This is
a routing binding only, not coverage evidence.

### Recovered Poisson q1 spatial, animal, and relatedness intercepts

The shared exact count fixture supplies three direct Poisson q1 intercept
targets at ten groups × 12 observations and seed `2026052801`, all with truth
0.45: `mc-0440` spatial, `mc-0447` animal, and `mc-0451` relatedness. Their
profiles returned `[0.3402096, 1.2249990]`, `[0.2357913, 0.7030618]`, and
`[0.2357913, 0.7030618]`, respectively; all had `conf.status = "profile"`,
convergence 0, and `pdHess = TRUE`. The formula grammar requires named
`coords` and `Q` fixture objects. These are routing bindings only, not coverage
evidence.

### Recovered NB2 q1 spatial, animal, and relatedness intercepts

The companion NB2 exact fixture adds `mc-0406` spatial, `mc-0407` animal, and
`mc-0408` relatedness mu-intercept targets at ten groups × 12, seed
`2026052802`, each with truth 0.45. Their direct profiles were
`[0.2973313, 1.0948530]`, `[0.3094870, 0.9996575]`, and
`[0.3094870, 0.9996575]`; all returned `conf.status = "profile"`, convergence
0, and `pdHess = TRUE`. These are routing bindings only, not coverage evidence.

### Recovered NB2 phylogenetic q1 intercept

The exact `mc-0405` fixture supplies a balanced eight-tip phylogeny, 24
observations per tip, seed `20260641`, and NB2 phylogenetic mu-intercept SD
truth 0.45. Its direct `sd:mu:phylo(1 | species)` profile returned
`[0.1494333, 0.6527877]`, `conf.status = "profile"`, convergence 0, and
`pdHess = TRUE`. This is a routing binding only, not coverage evidence.

### Gaussian recovery boundary

Outside `mc-0270` and the documented meta-V negative control, no Gaussian
model-surface row currently has a complete recoverable contract. The q3 ML
Gaussian mu-slope DGP is a near miss for the REML `mc-0269` route, and the
remaining ordinary fixtures establish admission or point estimates but lack a
reusable exact-DGP/profile-rung source. All 31 Gaussian structured rows remain
unbound: their legacy q-series labels do not identify an exact historical
component or target. They must not be filled by heuristic provider/q matching.
