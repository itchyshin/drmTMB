# Arc 3a recovery campaign manifest: positive-continuous structured `mu`

**Status:** PRIMARY CERTIFICATION COMPLETE WITH ITS MIXED FROZEN-GATE VERDICT;
FRESH PHYLOGENETIC ADDENDUM COMPLETE. Totoro completed all 6,000 primary fits
from clean source `0ef41a69` and all 2,400 addendum fits from the engine-identical
`d00da037` source. **Predeclared maximum decision ceiling:**
`point_fit_recovery` for each of Gamma–`phylo()`, lognormal–`phylo()`, and
lognormal–`relmat()` q1 `mu` intercepts under native-TMB univariate ML. The
primary decision promotes only lognormal–`relmat()`; both phylogenetic routes
retain the primary campaign's HOLD. A separately predeclared, freshly seeded
addendum subsequently certifies both phylogenetic routes at the same ceiling
using the exact design-conditioned GLS intercept oracle and structured-field
projection gates. Existing Gamma–`relmat()` is a positive comparator, not a
new promotion. The original threshold was not relaxed or rewritten. Compact
primary results and hashes are retained under
`docs/dev-log/simulation-artifacts/2026-07-14-arc3a-positive-continuous-structured-mu-recovery/`.
Compact addendum results and hashes are retained under
`docs/dev-log/simulation-artifacts/2026-07-14-arc3a-phylo-recovery-addendum/`.

## Certified result

Every scheduled route/rung has 400/400 fit successes, 400/400 analysis
successes, 400/400 optimizer convergence-zero results, and 400/400 positive-
definite Hessians. No boundary, gross-sigma, or other failure-stage event
occurred. The comparator and all shared gates pass. All 1,200 paired
lognormal-relatedness `K`/`Q` fits pass the representation tolerances with zero
tolerance failures.

Lognormal–`relmat()` passes every frozen cell gate and reaches
`point_fit_recovery`. Gamma–`relmat()` passes and retains its existing
`point_fit_recovery` state. Gamma–`phylo()` and lognormal–`phylo()` remain
`implemented`: their final-rung intercept RMSEs are `0.1930` and `0.1934`,
above the frozen `0.12` rule, although every other final-rung scalar target,
the field diagnostics, and the information-response gate pass.

Independent source and mathematical review found that the phylogenetic HOLD
is expected for the balanced Brownian-tree DGP. Its realized field mean has
variance `tau^2 * (1 - 1/M) / log2(M)`, which implies an oracle-scale
fixed-intercept SD of about `0.203` at `M = 64`. The frozen `0.12` threshold is
therefore unattainable at this ladder even with known covariance and
negligible observation noise. The threshold is not relaxed post hoc; see the
artifact README for the derivation and exact observed values.

The fresh addendum completed 2,400/2,400 valid fits: 400 replicates for each
phylogenetic family at `M = 16, 32, 64`. Observed/design-oracle intercept RMSE
ratios range from `0.9063` to `1.0294`; structured-projection correlations
range from `0.9969` to `0.9989`; and projection-residual RMSE ranges from
`0.00986` to `0.01939`. Every predeclared addendum gate passes. The final Arc
3a decisions are therefore `point_fit_recovery` for Gamma–`phylo()`,
lognormal–`phylo()`, and lognormal–`relmat()`, with no interval or coverage
promotion.

This study follows the ADEMP structure of Morris, White, and Crowther (2019),
*Using simulation studies to evaluate statistical methods*, and the transparent
simulation-reporting items of Williams et al. (2024). It implements the model
and units frozen in
`docs/dev-log/2026-07-14-arc3a-symbolic-alignment.md:10-115,163-181,253-276`,
the public boundary in
`docs/dev-log/2026-07-14-arc3a-api-rejection-matrix.md:19-84`, and the
all-attempted ledger evidence requirement in
`docs/dev-log/2026-07-14-arc3a-ledger-migration-plan.md:83-111`.

## A — Aims

**Primary aim.** Determine whether the three new native-TMB q1 structured
`mu` routes recover their fixed `mu` coefficients, fixed `sigma` coefficient,
and structured scale across a predeclared information ladder, with every
attempted fit retained.

**Secondary aims.** Verify that lognormal–`relmat()` fits to equivalent `K`
and `Q = solve(K)` inputs are numerically equivalent; confirm that the existing
Gamma–`relmat()` q1 route remains a stable positive comparator; and diagnose
conditional-field recovery without treating conditional modes as unbiased
fixed-parameter estimators.

This campaign does **not** evaluate confidence intervals, coverage, tests,
power, REML, structured slopes, structured `sigma`, q2+, simultaneous
structured providers,
newdata prediction, bivariate models, or Julia parity.

## D — Data-generating mechanism

### Hierarchical model

For structured level `j = 1, ..., M` and within-level observation
`k = 1, ..., 20`, draw `x_jk ~ N(0, 1)` and use

\[
\eta_{\mu,jk}=\beta_0+\beta_x x_{jk}+b_j,
\qquad
\eta_{\sigma,jk}=\beta_\sigma,
\qquad
b\sim N(0,\tau^2 C).
\]

The fixed truth is

\[
(\beta_0,\beta_x)=(0.20,0.35),\qquad
\beta_\sigma=\log(0.35),\qquad
\tau=0.50.
\]

Thus `beta_mu` and `tau` are in log-response location units for lognormal and
log-mean units for Gamma. `exp(beta_sigma) = 0.35` is the conditional `sdlog`
for lognormal and the conditional coefficient of variation for Gamma; it is
not an original-response residual SD. These are the package parameterizations
documented in
`docs/dev-log/2026-07-14-arc3a-symbolic-alignment.md:58-114`.

Conditional responses are generated as

\[
Y_{jk}\mid b \sim
\begin{cases}
\operatorname{Lognormal}(\eta_{\mu,jk},0.35), & \text{lognormal},\\
\operatorname{Gamma}(a=0.35^{-2},\ s=\exp(\eta_{\mu,jk})0.35^2),
& \text{Gamma}.
\end{cases}
\]

Every fit uses `sigma ~ 1`, `REML = FALSE`, and the canonical unlabelled
intercept-only structured formula. No data are missing and no response is
clipped or replaced.

### Provider geometry

For each rung, level names are `g001`, ..., `gMMM` and every matrix/tree is
stored with this exact order.

- **Phylogeny:** use one fixed, deterministic, fully balanced binary tree per
  rung with `M` a power of two, positive unit branch lengths, and identical
  root-to-tip distance for all tips. Give its tips the level names above. The
  package normalizes the ultrametric tree to unit root-to-tip height, yielding
  the unit-diagonal tip correlation `C_T` described in
  `R/phylo-utils.R:210-244,247-338`. Generate the latent tip field directly as
  `N(0, tau^2 C_T)` in the formula's tip order.
- **Relatedness:** set `K[j,l] = 0.5^abs(j-l)` with matching row and column
  names. This AR(1) covariance is positive definite and has `diag(K) = 1`, so
  `tau = 0.50` is both the fitted covariance multiplier and every level's
  marginal latent SD. Set `Q = solve(K)` without rounding. Generate one field
  from `N(0, tau^2 K)` and reuse the identical response data for the paired
  lognormal `K` and `Q` fits. This avoids the arbitrary-diagonal estimand
  problem documented in
  `docs/dev-log/2026-07-14-arc3a-symbolic-alignment.md:31-42`.

No identity covariance is used in the certification campaign. Phylogenetic
and relatedness results are not pooled because they use different dependence
geometries.

### Conditions and fit routes

| DGP cell | Fit representation(s) | Role |
| --- | --- | --- |
| Gamma × phylogeny | `phylo(1 | id, tree = tree)` | New cell |
| Lognormal × phylogeny | `phylo(1 | id, tree = tree)` | New cell |
| Lognormal × relatedness | `relmat(1 | id, K = K)` and `relmat(1 | id, Q = Q)` on the same data | New cell plus representation parity |
| Gamma × relatedness | `relmat(1 | id, K = K)` | Existing positive comparator |

The information ladder is `M in {16, 32, 64}` with exactly 20 observations per
level, giving `N in {320, 640, 1280}`. The number of within-level observations
is held fixed so increasing `M` targets information about the structured scale
rather than confounding the ladder with within-level replication.

### Replicates, seeds, and fit count

Use exactly **400 replicates per DGP cell and rung**. Set master seed
`2026071403`, generate all replicate-level seeds once with
`sample.int(.Machine$integer.max, size, replace = FALSE)`, and write the seed
manifest before fitting. Provider, family, rung, replicate, DGP seed, and fit
representation are immutable keys. The paired lognormal K/Q fits share the DGP
seed and data but have distinct fit-route keys.

The certification count is

\[
3\ \text{rungs}\times400\ \text{replicates}\times5\ \text{fit routes}
=6{,}000\ \text{attempted fits}.
\]

Preflight adds five local toy-smoke fits, the same five-fit read-back smoke from
the staged Totoro snapshot, and a 10-replicate-per-route Totoro pilot (50 fits).
Thus the complete plan is **6,000 certification fits + 60 preflight fits =
6,060 planned fits**. Smoke and pilot fits are never pooled into certification
denominators. Four hundred attempts give a
binomial MCSE of 0.0109 at a 95% success rate; three MCSEs are 0.0327, smaller
than the predeclared five-percentage-point distinction between a 95% passing
rate and a 90% rate that would be substantively inadequate. Continuous-
performance MCSEs are computed from the realised replicate distribution and
must satisfy the predeclared precision gates below.

## E — Estimands and targets

| Target | Truth | Extractor | Units / interpretation |
| --- | ---: | --- | --- |
| `beta_mu[(Intercept)]` | 0.20 | `coef(fit)$mu` / `fit$coefficients$mu` | Log-response location for lognormal; log-mean for Gamma |
| `beta_mu[x]` | 0.35 | same | Change in the relevant `mu` predictor per one-unit `x` |
| `beta_sigma[(Intercept)]` | `log(0.35)` | `coef(fit)$sigma` | Log-sdlog for lognormal; log-CV for Gamma |
| `tau` | 0.50 | named value in `fit$sdpars$mu` | Phylogenetic marginal tip SD; relatedness multiplier and common marginal SD because `diag(K)=1` |
| conditional field `b_j` | replicate-specific draw | aligned `ranef(fit, "phylo_mu")` or `ranef(fit, "relmat_mu")` | Conditional-mode prediction on the `mu` linear-predictor scale; never rescale by `tau` again |

The known tree, `K`, and `Q` are inputs, not estimands. Conditional-field RMSE
and correlation are secondary prediction diagnostics; their truth is stored per
replicate, but no claim of unbiased per-level estimation is made. Conditional
training-data prediction must also satisfy the decomposition identity in
`docs/dev-log/2026-07-14-arc3a-symbolic-alignment.md:210-221,242-248`.

## M — Methods

Fit only drmTMB's native TMB univariate ML/Laplace route with the public syntax
frozen in `docs/dev-log/2026-07-14-arc3a-api-rejection-matrix.md:19-38`.
`u_phylo` is integrated by Laplace; fixed effects and `log_sd_phylo` are
optimized. Standard errors must remain enabled so `pdHess` can be evaluated,
but no Wald interval is calculated or summarized.

Gamma–`relmat(K)` is the sole comparator because it is the existing q1 native
route (`mc-0248`) and exercises the same structured prior. It is not an
independent estimator and cannot validate the new likelihood by itself.
No additional package comparator is included because this is a bounded engine
recovery gate, not a method-comparison study.

## P — Performance measures

All summaries are by fit route and information rung. Do not pool families,
providers, representations, rungs, local smoke, or hosts.

For scalar target `theta`, among fits meeting the `analysis-success` definition
below, report

\[
\operatorname{bias}(\hat\theta)=n_s^{-1}\sum(\hat\theta_r-\theta),
\qquad
\operatorname{RMSE}(\hat\theta)=
\sqrt{n_s^{-1}\sum(\hat\theta_r-\theta)^2}.
\]

Also report median error, 5th/95th error quantiles, mean estimate, and `n_s`.
Bias MCSE is `sd(theta_hat - theta) / sqrt(n_s)`. RMSE MCSE is obtained from an
exactly 2,000-resample deterministic nonparametric bootstrap of squared errors using a
separate recorded summary seed. Do not calculate confidence-interval coverage,
Type I error, power, or any interval-based measure.

For the replicate-specific conditional field, report level-aligned RMSE and
Pearson correlation within each replicate, then the median and 10th/90th
quantiles across successful fits. Report run time per fit descriptively.

### Attempt, success, and failure denominators

Every scheduled route/rung/replicate is an **attempt**, even if data generation,
object construction, fitting, Hessian calculation, or extraction fails. The raw
table must contain one row per attempt with no retry replacing the original.
Any permitted diagnostic retry is a new suffixed row and is excluded from the
predeclared 6,000-fit denominator.

Record mutually exclusive `failure_stage` values:

`none`, `dgp`, `provider_build`, `fit_error`, `optimizer`, `hessian`,
`extractor`, or `nonfinite`.

- **Fit success:** the fit returns; `fit$opt$convergence == 0`; objective and
  all target estimates are finite; the intended named `sdpars$mu` value and
  random-effect block exist; and no extractor or scale-identity check fails.
- **Analysis success:** fit success plus a finite Hessian diagnostic. Bias and
  RMSE use all analysis-success estimates whether `pdHess` is TRUE or FALSE;
  `pdHess` is reported separately rather than used for silent deletion.
- **`pdHess` rate:** `isTRUE(fit$sdr$pdHess)` divided by all 400 attempts.
- **Boundary rate:** `tau_hat <= 0.05` or `tau_hat >= 2.00`, divided by all
  attempts. Nonfinite `tau_hat` is a failure, not a boundary success.
- **Gross sigma flag:** `exp(beta_sigma_hat)` outside `[0.0875, 1.40]`; report
  separately and do not relabel it as a variance-component boundary.

Report attempted, fit-success, analysis-success, convergence-zero, `pdHess`,
boundary, gross-sigma, and every failure-stage count. Bias/RMSE tables must show
both the 400-attempt denominator and their `n_s` conditional denominator.

### K/Q representation parity

For each paired lognormal–relatedness replicate, align levels by name and
compare only when both fits are analysis-successful. Predeclared tolerances are:

- absolute objective difference `<= 1e-6`;
- maximum absolute difference in fixed `mu` and `sigma` coefficients `<= 1e-5`;
- absolute difference in `tau` `<= 1e-5`; and
- maximum absolute difference in the aligned conditional field `<= 1e-4`.

These follow the repository's existing K/Q objective and parameter tolerances
in `tests/testthat/test-reml-structured-location.R:318-321`. Record paired
success, success-status mismatch, and every tolerance failure against all 400
pairs per rung.

## Predeclared PASS/HOLD decision

A new cell receives `point_fit_recovery` only if **all** applicable gates pass.
The comparator must pass the same recovery gates but receives no new state.
There is no post-hoc threshold relaxation or selective rung removal.

### Smoke gate — all five fits required

Using replicate 1 at `M = 16`, run exactly one fit for each of the five routes
with one core. PASS requires all five to return convergence zero, finite
targets, the correct named `sdpars$mu` and random block, non-empty raw output,
and the correct conditional prediction decomposition. The K/Q pair must also
meet all four parity tolerances. Inspect `str()` of one phylo fit and both
relmat fits. Any failure is **HOLD: repair before Totoro**; the smoke is not
evidence for ledger promotion.

### Certification gates

| Gate | Numeric PASS rule per route unless stated otherwise |
| --- | --- |
| Completeness | Exactly 400 immutable raw attempt rows at each rung; no missing or duplicate keys; total exactly 6,000 certification rows |
| Fit success | At least 380/400 (95%) at **every** route × rung |
| `pdHess` | At least 380/400 (95%) at every route × rung, denominator = all attempts |
| Structural boundary | At most 8/400 (2%) at every route × rung |
| Gross sigma | At most 8/400 (2%) at every route × rung |
| Final-rung bias | At `M = 64`: absolute bias `<= 0.05` for each fixed `mu` and `sigma` coefficient; absolute bias `<= 0.075` for `tau` (15% of truth) |
| Final-rung RMSE | At `M = 64`: RMSE `<= 0.12` for every fixed coefficient and `<= 0.125` for `tau` (25% of truth) |
| Information response | For each route, `tau` RMSE at `M = 64` must be `<= 0.85` times its `M = 16` RMSE; no fixed-coefficient RMSE at `M = 64` may exceed its `M = 16` RMSE |
| Monte Carlo precision | At `M = 64`, bias MCSE `<= 0.025` and bootstrap RMSE MCSE `<= 0.025` for every scalar target |
| Field recovery | At every route × rung: median conditional-field correlation `>= 0.80` and median conditional-field RMSE `<= 0.25` (half the true `tau`) |
| K/Q paired availability | At least 380/400 pairs are jointly analysis-successful at each rung; success-status mismatch at most 4/400 (1%) |
| K/Q numerical parity | Every jointly analysis-successful pair meets all four predeclared parity tolerances; zero tolerance failures |
| Comparator | Gamma–relmat K passes every non-parity gate; it remains `mc-0248` and is not counted as an Arc 3a promotion |

If a route fails any gate, its decision is **HOLD** at its prior ledger state.
Other new cells may pass independently only if the failure is cell-specific and
the shared-engine, scale-identity, seed, and output-integrity gates remain
valid. The summarizer propagates the Gamma-relmat comparator and lognormal K/Q
parity decisions to all three new cells as shared gates. Any wrong likelihood
units, double scaling, denominator loss, K/Q non-equivalence, comparator
failure, shared extractor defect, or corrupted seed/output manifest places
**all three new cells on HOLD**.

The thresholds support only point-fit recovery over the exact tested domain.
They do not imply interval feasibility, nominal coverage, `inference_ready`,
`supported`, broad provider support, or extrapolation below `M = 16` or beyond
the fixed DGP values.

## Raw record and artifact contract

The raw certification table must include at least:

`campaign_id`, source commit SHA, host, phase, family, provider, representation,
`M`, `n_per_level`, `N`, replicate, DGP seed, fit key, attempted, failure stage,
error class/message, elapsed seconds, convergence code/message, objective,
the serialized fixed-parameter Hessian-covariance diagnostic, `pdHess`, boundary
and gross-sigma flags, every truth and estimate, extractor
names, prediction-identity error, conditional-field RMSE/correlation, tree/K/Q
hashes, and session manifest hash.

Write checkpointed per-shard outputs and combine them by immutable key. The
combined raw TSV is authoritative. The summarizer must reconstruct every table
from raw data and emit its own hash. Save `sessionInfo()`, R/TMB compiler
details, source SHA, dirty-state declaration, command line, master/summary
seeds, provider-object hashes, raw/summary SHA-256 hashes, attempted counts,
worker count, and wall time. Compact reviewed summaries may enter the repo;
raw campaign data remain local and never become GitHub Actions artifacts.

## Totoro execution contract

No compute is authorized by this manifest alone. After engine/tests are green
and the smoke passes:

1. Reach Totoro through the existing ControlMaster socket and verify
   `echo OK; nproc`; abort on failed non-interactive reachability.
2. Stage an exact source snapshot, record its commit and dirty-state manifest,
   verify key Arc 3a source/test/runner files and hashes, and build/load that
   snapshot before fitting. Never use a stale installed drmTMB.
3. Set `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, `MKL_NUM_THREADS=1`, and
   `TMB_NTHREADS=1`.
4. Run the five-fit smoke with one worker and inspect the first raw rows. Then
   run a 10-replicate-per-route pilot with at most 10 workers; pilot rows are
   diagnostics and do not enter certification denominators.
5. Launch the checkpointed 6,000-fit certification campaign with at most
   **90 workers** (hard ceiling 96, below the standing 100-core shared-server
   limit). Poll the first completed shard immediately and abort on empty,
   all-NA, wrong-SHA, wrong-fit-count, repeated-seed, or scale-identity output.
6. On interruption, resume missing immutable keys only. Never overwrite or
   substitute a failed attempt. Record worker cleanup and confirm no orphan R
   processes remain.
7. Copy compact summaries, manifests, and hashes back for review; keep raw
results local. Do not run any simulation/recovery fit on GitHub Actions.

Before evaluating recovery, the summarizer authenticates the raw table against
the independently reconstructed frozen schedule. It requires exact agreement
for the Cartesian route/rung/replicate tuples, immutable global indices,
round-robin shard membership, master-seed sequence, `M`, `n_per_level`, `N`,
truth values, route/family/provider/representation/role mappings, source SHA,
campaign ID, host class, and clean-source declaration. It verifies each shard's
seed manifest and session-manifest hash, requires the exact host, parsed
effective `load=installed` mode, and installed-snapshot certification command,
and recomputes the balanced-tree and
K/Q provider hashes. It then regenerates each latent field from its recorded
DGP seed and frozen covariance, requires exact level names and field values,
and recomputes field RMSE/correlation and all fit-, analysis-, Hessian-,
boundary-, and gross-sigma flags. Any mismatch is a hard error before gate
evaluation; missing or altered provenance cannot become a HOLD/PASS result.

The executable shard contract is deterministic round-robin partitioning of the
frozen 6,000-row schedule:

```sh
Rscript tools/arc3a-positive-continuous-structured-mu-recovery.R \
  --mode=certification --load=installed \
  --shard-index="$i" --shard-count="$workers" \
  --output="$run_root/raw-shard-$i.tsv" \
  --seed-output="$run_root/seeds-shard-$i.tsv" \
  --session-output="$run_root/session-shard-$i.txt"
```

`global_fit_index` is immutable before partitioning. The complete shard set
must reconstruct indices 1–6,000 and unique `fit_key` values exactly once. Run
`tools/summarize-arc3a-positive-continuous-structured-mu-recovery.R` only after
all shards finish; it refuses missing/duplicate indices, dirty or mixed source
SHAs, non-certification rows, missing shard IDs, non-constant fields within a
structured level, scale-identity failures, non-canonical seed/session/provider
provenance, a bootstrap count other than exactly 2,000, or a denominator other
than 6,000 before evaluating the predeclared gates.

## Williams transparent-reporting self-audit

| # | Item | Status | Where addressed |
| --- | --- | --- | --- |
| 1 | Aims | ✅ | Primary and secondary aims above; claim ceiling explicit |
| 2 | DGP + n_sim justified | ✅ | Hierarchy, equations, truth, provider geometry, ladder, 400-replicate precision, 6,000-fit certification count, and 6,060 total scheduled fits above |
| 3 | Estimand / target | ✅ | Scalar and replicate-specific field targets table above |
| 4 | Methods literature cited | ✅ | ADEMP and transparent-reporting sources cited at the top; the package likelihood and provider contracts are cited to the symbolic freeze |
| 5 | Performance measures (formulas) | ✅ | Bias/RMSE formulas, denominators, diagnostics, parity, MCSEs, and PASS/HOLD thresholds above |
| 6 | Software / packages / versions | ✅ | `summary-manifest.txt` records R 4.5.3, Ubuntu 24.04.4, source SHA, host, workers, seeds, and content hashes |
| 7 | Code for DGP available | ✅ | The deterministic runner was executed from the clean, read-back `0ef41a69` installed snapshot |
| 8 | Code for performance measures | ✅ | The standalone fail-closed summarizer, exact 2,000-resample RMSE MCSE, and provenance authentication are implemented and locally rehearsed |
| 9 | Worked-example case study | partial | Not part of this internal campaign; the exact user-facing fit remains a documentation closeout item rather than simulation evidence |
| 10 | Full performance table | ✅ | Compact all-route/rung target, diagnostics, parity, decision, and failure-stage tables are checked in; the authenticated 6,000-row raw table remains local on Totoro |
| 11 | MCSE reported alongside | ✅ | `target-recovery-summary.tsv` reports bias MCSE and exactly 2,000-resample bootstrap RMSE MCSE beside every scalar target |

## Primary-campaign Fisher verdict

**CERTIFICATION AUTHENTIC; APPLY THE FROZEN MIXED VERDICT.** The estimands,
units, information ladder, seeds, fit count, denominator rules, diagnostics,
representation parity, and PASS/HOLD thresholds remained frozen through
execution. Fisher's pre-run review returned READY, the clean Totoro snapshot
and first outputs were read back before scale-up, and the fail-closed
summarizer authenticated all 6,000 attempts. Lognormal–`relmat()` may be
promoted to `point_fit_recovery`; both phylogenetic routes must remain
`implemented` under the frozen gate. The campaign does not authorize a new
interval, coverage, inference-ready, supported, REML, slope, or broader-
provider claim.

## Final addendum verdict

**PASS at the frozen `point_fit_recovery` ceiling.** Fisher and Noether
independently verified all 2,400 addendum denominators, compact hashes,
design-conditioned oracle calculations, structured projections, MCSEs, and
source-tree identity with the primary implementation. Rose verified that the
ledger preserves the primary HOLD as history and uses the addendum only for
the two phylogenetic promotions. No interval, coverage, inference-ready,
supported, REML, slope, or broader-provider claim follows.
