# Arc 3a phylogenetic recovery addendum

**Status:** PREDECLARED AND FISHER/NOETHER-APPROVED; NOT YET RUN. This
addendum is a narrow continuation
of the approved Arc 3a goal. It does not alter the immutable 6,000-fit primary
certification, reuse its results for promotion, or widen the model surface.
Fisher and Noether must approve this contract before new fits begin.

## Reason for the addendum

The primary campaign's universal fixed-coefficient RMSE cap was attainable for
the AR(1) relatedness geometry but impossible for its balanced phylogeny. For
`M = 2^L` unit-branch balanced tips normalized to unit tree height,

\[
\operatorname{Var}(\bar b)
=
\tau^2\frac{1-1/M}{\log_2 M}.
\]

The fixed intercept and the realized field's constant ancestral mode are
therefore weakly distinguishable in one tree. With the frozen `tau = 0.5`, the
model-implied standard deviation of that mode is `0.2421`, `0.2201`, and
`0.2025` at `M = 16, 32, 64`; the observed primary-campaign intercept RMSEs
track those values. This is a compatibility defect between the original
universal threshold and provider geometry, not evidence of an engine defect.
The corresponding closed-form values including response information are
`0.242850906`, `0.220519628`, and `0.202759286`.

The addendum evaluates the same population intercept honestly against its
known-covariance sampling distribution. It does not center the latent field,
select a weaker tree, raise the old threshold, change the estimand, or reuse
the old seeds.

## Frozen model and scope

The equations, syntax, truth, balanced-tree construction, likelihoods,
extractors, `M = {16,32,64}`, 20 observations per tip, and scalar/field targets
remain exactly those in the primary manifest. Only two fit routes run:

- Gamma × `phylo(1 | id, tree = tree)`;
- lognormal × `phylo(1 | id, tree = tree)`.

This is native TMB, univariate ML, pure `mu`, one unlabelled q1 intercept. It
does not add slopes, labels/q2+, structured `sigma`, joint `mu`/`sigma`,
multiple providers, spatial/animal, bivariate, REML, intervals, coverage,
inference-ready, supported, or Julia claims.

## Fresh schedule and provenance

Use exactly 400 fresh replicates per route and rung:

\[
2\ \text{routes}\times3\ \text{rungs}\times400
=2{,}400\ \text{new fits}.
\]

The exact route order is `gamma_phylo`, then `lognormal_phylo`; within each
route, schedule rows are ordered by `M = 16, 32, 64` and then replicate
`1:400`. The DGP-seed table is ordered by DGP cell in the same family order,
then `M`, then replicate. Run `set.seed(2026071431)` once and generate exactly
2,400 independent integer seeds with
`sample.int(.Machine$integer.max, 2400, replace = FALSE)`. The two families are
not paired. The separate summary seed is `2026071437`. For scalar `target` at
route `route` and rung `M`, set the bootstrap seed to
`2026071437 + match(route, route_order) * 100 + M +
match(target, c(beta0, beta_x, beta_sigma, tau))`, then use exactly 2,000
nonparametric resamples of the analysis-success squared errors. Every attempt
is retained. The runner must use a distinct
`arc3a_phylo_recovery_addendum_20260714` campaign ID and
`phylo_certification` phase, authenticate the clean installed source, rebuild
the complete seed/schedule/tree contract, and refuse any other route, rung,
replicate count, or within-tip replication.

Raw output stays local on Totoro. Compact summaries, hashes, all denominators,
and the immutable primary-campaign decision hashes may enter the repository.
The addendum is valid only while the primary comparator, K/Q parity, and shared
gates remain PASS under these pinned identities:

- primary fitted source: `0ef41a6904372de1790a63ecbf233758221d52ff`;
- primary summarizer fix: `5f324a6876c1c2665598774a2717e8ee06524f4b`;
- combined raw SHA-256:
  `b303aab6781770e14be096b69c95b5da0e803f703cf3321baa91750a6465dcd3`;
- route-decision SHA-256:
  `b801eb545ad43ea852ef3242ab076f8da4c96e3ae342253ab4f311a5e0d9528e`;
- cell-decision SHA-256:
  `db6e7b0da4e4cd97d00664885b2b231794e9f9f3412112138ea60d8ad3f25076`;
- K/Q-parity SHA-256:
  `aea481c2a564663c1b10371ece780aeeefa431f0c47abf2d90d9e67b42c5e935`.

The addendum source may change tools, tests, and documentation, but `R/` and
`src/` must be byte-identical to `0ef41a69`. Otherwise inherited comparator and
shared gates are invalid and the addendum must abort.

## Oracle-relative intercept criterion

For each rung, the balanced-design floor and dominant closed-form intercept
scale is

\[
s_{0,M}
=
\sqrt{
  \tau^2\frac{1-1/M}{\log_2 M}
  + \frac{\sigma^2}{20M}
}.
\]

The residual term is exact for lognormal on the log scale when the slope is
known or the realized predictor is covariance-orthogonal to the intercept.
Because the frozen DGP jointly estimates a random realized `x`, the hard gate
uses the replicate-specific design-adjusted known-covariance oracle

\[
s_{0,M,r}^2
=
\left[
  \left(X_r^\top V_r^{-1}X_r\right)^{-1}
\right]_{00},
\qquad
V_r=\tau^2 Z_r C_M Z_r^\top+\sigma^2 I,
\]

and reports

\[
s_{0,M}^{\mathrm{design}}
=
\sqrt{n_s^{-1}\sum_{r\in S}s_{0,M,r}^2},
\]

where `S` is the analysis-success subset and `n_s = |S|`. This matches the
subset used for observed RMSE; both `n_s` and the 400-attempt denominator are
reported.

The closed form remains a transparent design-floor diagnostic. Gamma with its
mean-CV parameterization has expected information `1 / sigma^2` for
`eta = log(mu)` and zero expected cross-information with `log(sigma)`, so the
same design-adjusted expression is its local-GLS analogue rather than an exact
finite-sample marginal variance after estimating `tau`. The addendum records
both oracle values, observed intercept RMSE, their ratio, and bootstrap RMSE
MCSE at every route/rung.

For the decomposition diagnostic, the exact realized structured-field
contribution to the GLS intercept is

\[
g_{0,r}
=
e_0^\top
\left(X_r^\top V_r^{-1}X_r\right)^{-1}
X_r^\top V_r^{-1}Z_r b_r.
\]

This reduces to the arithmetic field mean only when the realized predictor is
covariance-orthogonal to the intercept. The arithmetic mean remains a
secondary reported diagnostic; hard decomposition gates use `g_0,r`.

The intercept gate passes only when all of the following hold:

1. absolute intercept bias is at most `0.05` at `M = 64`;
2. observed/design-adjusted-oracle intercept RMSE is in `[0.80, 1.20]` at
   every rung;
3. intercept RMSE at `M = 64` does not exceed its value at `M = 16`;
4. bias MCSE and bootstrap RMSE MCSE are each at most `0.025` at `M = 64`;
5. after subtracting the exact `g_0,r` structured-field projection from the
   intercept error, residual RMSE is at most `0.05` at every rung; and
6. correlation between intercept error and `g_0,r` is at least `0.95` at every
   rung.

The two-sided oracle-ratio band detects both unexplained excess variation and
artificially low variation from an altered estimand or shrinkage. The
field-projection decomposition is diagnostic confirmation, not a replacement
estimand: `beta0` remains judged against the unchanged truth `0.20`.

For each replicate define `e_r = beta0_hat_r - beta0` and the exact
design-conditioned structured projection `g_0,r` above; the decomposition
residual is `d_r = e_r - g_0,r`. The arithmetic field mean
`bar(b)_r = M^-1 sum_j b_jr` is reported only as a secondary diagnostic. Every
RMSE, oracle ratio, residual RMSE, and correlation uses all analysis-success
rows and reports both `n_s` and the 400-attempt denominator.

With 400 replicates, the approximate relative RMSE MCSE is
`1 / sqrt(800) = 0.0354`; the `0.80`-`1.20` oracle-ratio band is therefore about
5.7 such MCSEs from unity and targets a material discrepancy rather than Monte
Carlo noise. The response-only reference SDs are approximately `0.0196`,
`0.0138`, and `0.0098` at the three rungs, so residual RMSE `0.05` and
correlation `0.95` are deliberately loose defect-detection thresholds rather
than precision claims.

## Gates retained from the primary campaign

Every non-intercept primary gate remains unchanged per route/rung:

- at least 380/400 fit successes and positive-definite Hessians;
- at most 8/400 structured boundaries and gross-sigma flags;
- final-rung absolute bias at most `0.05` for `beta_x` and `beta_sigma`, and
  at most `0.075` for `tau`;
- final-rung RMSE at most `0.12` for `beta_x` and `beta_sigma`, and `0.125` for
  `tau`;
- `tau` RMSE at `M = 64` no more than `0.85` times its `M = 16` RMSE, with no
  non-intercept fixed-effect RMSE increase;
- final-rung bias and bootstrap-RMSE MCSE at most `0.025`;
- median conditional-field correlation at least `0.80` and median field RMSE
  at most `0.25` at every rung;
- exact prediction decomposition and all provenance/integrity checks.

Each phylogenetic cell reaches `point_fit_recovery` only if its fresh route
passes every retained gate and every oracle-relative intercept gate, and the
immutable primary shared gates remain PASS. Otherwise it stays `implemented`.
There is no selective rung deletion, retry substitution, post-result threshold
change, or cross-family pooling.

## Execution gate

Before Totoro scale-up: parse and focused tests must cover the new mode and
summarizer fail-closed paths; run one fresh fit per route locally; stage a
clean committed snapshot; install it in an isolated library; run and read back
one two-route smoke; then run a 10-replicate-per-route pilot. Use
`OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, `MKL_NUM_THREADS=1`, and
`TMB_NTHREADS=1`. Never exceed 96 workers or the standing 100-core account
limit, and never use GitHub Actions for these simulations.
The pilot is abort-only: its results may stop execution but may not change any
threshold, algorithm, seed, route, or reporting rule before certification.

## Independent pre-run verdicts

Noether verified the balanced-tree identity, Gamma expected-information
statement, replicate-specific design oracle, exact structured-field projection,
and the Woodbury implementation against dense GLS to machine precision.
Fisher verified the fresh-seed schedule, MCSE/error budget, all retained gates,
source-tree pin, authenticated primary evidence dependency, and fail-closed
missing/tampered-artifact tests. Both returned READY before any addendum pilot
or certification result was seen.
