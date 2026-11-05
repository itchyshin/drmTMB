# Bernoulli phylogenetic SD calibration pilot design

Status: **timing and fit-recovery pilot; no calibration claim**  
Design date: 2026-10-19  
Engine: native R/TMB  
Compute target: Totoro, maximum four workers  
Independent source review: NotebookLM account `itchyshin@gmail.com`; existing
methods notebook and primary-source audit in `research.md`

This pilot asks whether the current Bernoulli phylogenetic SD route can recover
a known log-SD slope and return usable profile intervals across a small,
predeclared information grid, and measures the cost of those fits. Three
replicates per cell cannot estimate coverage reliably. Do not interpret pilot
coverage as a rate, change public claims from it, or use its seeds in later
production.

## A: Aims

The primary aim is to measure runtime, fit completion, slope recovery, clamp
status, and profile-interval availability for a synthetic Bernoulli
phylogenetic random-intercept SD regression under four group-count and
within-group replication designs.

The secondary aim is to check that nested subsets preserve the intended
covariance and that all attempted fits, including failed or boundary-limited
fits, remain available for later study planning.

This pilot does not estimate interval coverage, recommend a minimum number of
tips or observations, or establish calibrated uncertainty.

## D: Data-generating mechanism

There are tips `g = 1,...,60`, with repeated Bernoulli observations `i` within
each tip. For each independent replicate, generate a rooted random tree with
`ape::rcoal(60)`, assign stable tip labels, and obtain the package's existing
phylogenetic covariance `K` with the same scaling used by the fitted model.
Generate a standardized tip-level predictor `z_g` and a single correlated
latent field

\[
u \sim N(0,K),\qquad
s_g=\exp\{\log(0.35)+0.45z_g\},\qquad
b_g=s_g u_g.
\]

For the largest design, generate 100 responses at each of 60 tips:

\[
Y_{ig}\mid b_g \sim \operatorname{Bernoulli}\!
  \left[\operatorname{logit}^{-1}(0.2+b_g)\right].
\]

The 16-tip designs use a seeded subset from that same replicate, retaining at
least one tip from each root daughter, and the corresponding pruned tree;
12-observation designs use the first 12 responses per retained tip. Retaining
both root daughter clades preserves the same covariance submatrix when the
tree is pruned. This nesting pairs information conditions within each
replicate and makes the covariance submatrix check explicit. The fitted
formula is `y ~ phylo(1 | species, tree = tree)` with
`sd(species, level = "phylogenetic") ~ z`. The covariance kernel is not
normalized or changed by the pilot.

| Factor | Levels | Use |
|---|---|---|
| Independent DGP replicate | 3 pilot seeds | Repeated timing and runner checks |
| Number of tips | 16, 60 | Independent-group information contrast |
| Observations per tip | 12, 100 | Within-tip information contrast |
| SD slope | 0.45 | Fixed truth for this single timing/recovery design |
| SD intercept | `log(0.35)` | Fixed truth |
| Fixed intercept | 0.2 | Fixed truth |

There are 4 nested design cells and 3 independent DGP replicates per cell,
giving 12 fits. Seeds are newly reserved for this pilot and must not overlap
with the existing ordinary Bernoulli campaign streams or the earlier
single-seed phylogenetic probes. Each replicate stores its generated truth,
fit status, convergence diagnostics, coefficient estimates, clamp status,
profile endpoints, elapsed time, and any error. A failed fit remains an
attempt; it is never silently dropped.

Three runs per cell let each design execute repeatedly and provide a rough
runtime distribution. They do not meet a Monte Carlo precision target for
coverage. A future calibration study must use a
predeclared coverage MCSE target. For a 95% interval and target MCSE at most
0.7 percentage points, the binomial approximation requires at least 970
independent attempts per declared calibration domain; use 1,000 as the initial
rounded target, then apply the previously approved staged decision rule and
retain all failures. A pilot cannot authorize that campaign.

## E: Estimands and targets

For every generated replicate, the primary recovery target is the log-SD
slope `alpha_1 = 0.45`; its estimator is the fitted coefficient for `z` in
`sd_phylo(species)`. The secondary coefficient target is the log-SD
intercept `alpha_0 = log(0.35)`, estimated by the intercept in the same
regression. The predicted SD at a declared predictor value `z` is
`exp(alpha_0 + alpha_1 z)`; report its fitted counterpart as a
descriptive recovery diagnostic in this pilot.

The interval target is whether the profile interval is returned, finite,
non-boundary, and contains `alpha_1` for each individual run. The fraction
containing truth is recorded as a pilot diagnostic with its denominator and
must not be labelled an estimated coverage rate. Runtime is wall-clock time
from model fit start through profile interval completion; generation and
installation time are recorded separately.

## M: Methods

Fit each synthetic data set once with the native R/TMB Bernoulli model and
request the 95% profile interval for the identified SD slope using the
existing fast profile precision. Record optimizer health, gradient,
Hessian status, clamp-band contact, profile status, and all interval
endpoints. The fit uses the current candidate source and an isolated package
library on Totoro. No competing estimator is included because this pilot
measures the intended package path, not estimator performance.

The scalar independent-cluster Laplace oracle used by the existing ordinary
Bernoulli pilot is not an oracle for a phylogenetically correlated latent
field. For this smoke, check the generated covariance and paired tree-pruning
identity directly, and retain numerical fit diagnostics. A separate
independent marginal-likelihood oracle and quadrature-stability study are
required before a phylogenetic calibration campaign. TMB and package
implementation are not independent validation sources.

The source review is bounded. Joe (2008) studies selected discrete-response
mixed-model Laplace bias, not SD-regression interval coverage. Stringer (2024)
studies adaptive quadrature for grouped models with group-invariant
covariance, not predictor-dependent latent SDs. Neither supplies a universal
integration order or calibration result for this target. See the primary
source checks and NotebookLM qualifications in `research.md`.

## P: Performance measures

Report all measures by design cell, retaining the total attempt denominator:

- Completion fraction: converged fits divided by all attempted fits.
- Mean log-SD slope error: mean of `estimate(alpha_1) - 0.45`; with three
  replicates this is descriptive.
- Root mean squared slope error: square root of the mean squared slope
  error; descriptive at this pilot size.
- Profile availability: count and fraction with finite endpoints,
  non-boundary profile status, and no clamp-limited status.
- Truth-in-interval count: number of returned intervals containing 0.45,
  shown as individual attempts and a count, never as calibrated coverage.
- Runtime: per-fit elapsed seconds, median, range, and total wall time.
- Monte Carlo standard errors: do not report a pilot coverage MCSE as
  though its estimate were informative. For a future calibration run with
  `n` independent attempts and empirical coverage `p_hat`, report
  `sqrt(p_hat * (1 - p_hat) / n)` and an exact binomial interval. For a mean
  recovery error report `sd(error) / sqrt(n)`; calculate uncertainty for RMSE
  with a replicate bootstrap or report its explicitly derived MCSE.

### Execution estimate and stop rule

The current local 60-tip, 100-observation profile probe took about 47 seconds
for one fit. A prior Totoro three-fit ordinary Bernoulli qualification took
32.725 seconds, but that model is simpler and is not a valid phylogenetic
runtime proxy. Budget **15 minutes wall time** for this 12-fit Totoro pilot,
including package setup and receipt writing, with at most four workers and
`OPENBLAS_NUM_THREADS=1`. Measure setup, fit, and profile times. Stop if total
runtime exceeds 30 minutes, if any path or
source hash does not match the sealed candidate, or if generated covariance
checks fail. No run may exceed the three-hour approval boundary; this design
does not authorize any later campaign.

The run receipt must bind the candidate source-tree hash, package tarball and
installed-binary hashes, R and package versions, operating system, worker
count, seed list, scripts, command, attempt ledger, and output hashes. Totoro
is the compute target. Use the existing attached
ControlMaster socket, a backed-up path under `~/hsq_work`, and a four-worker
cap. If Totoro becomes unavailable, pause and re-route through a separate
pre-run estimate before using DRAC.

## Williams et al. 2024 self-audit

| # | Item | Status | Where addressed |
|---|---|---|---|
| 1 | Aims | ✅ | A: Aims |
| 2 | DGP + n_sim justified | ✅ | D: DGP; pilot count is for timing, not coverage |
| 3 | Estimand / target | ✅ | E: targets |
| 4 | Methods literature cited | ✅ | M: methods and source limits |
| 5 | Performance measures (formulas) | ✅ | P: performance measures |
| 6 | Software / packages / versions | ✅ | Totoro environment receipt and `sessionInfo()` |
| 7 | Code for DGP available | ✅ | `bernoulli-phylo-calibration-pilot.R` |
| 8 | Code for performance measures | ✅ | `summarize-bernoulli-phylo-calibration-pilot.R` |
| 9 | Worked-example case study | gap | Outside this timing pilot |
| 10 | Full performance table | gap | A 12-fit smoke cannot support the full report |
| 11 | MCSE reported alongside | partial | Formula and production target specified; no calibration estimate from this pilot |

The 11 checklist questions are from Williams et al. (2024), reproduced in the
simulation-design skill's reporting checklist. The pilot's incomplete items
are deliberate boundaries, not claims of a completed simulation study.

## References

- Morris, T. P., White, I. R., & Crowther, M. J. (2019). Using simulation
  studies to evaluate statistical methods. *Statistics in Medicine*, 38,
  2074–2102. [doi:10.1002/sim.8086](https://doi.org/10.1002/sim.8086).
- Williams, C. T. et al. (2024). Transparent reporting items for simulation
  studies evaluating statistical methods: Foundations for reproducibility
  and reliability. *Methods in Ecology and Evolution*, 15, 1926–1939.
  [doi:10.1111/2041-210X.14415](https://doi.org/10.1111/2041-210X.14415).
- Joe, H. (2008). Accuracy of Laplace approximation for discrete response
  mixed models. *Computational Statistics & Data Analysis*.
  [Publisher record](https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533).
- Stringer, A. (2024). Exact gradient evaluation for adaptive quadrature
  approximate marginal likelihood in mixed models for grouped data.
  [arXiv:2310.01589](https://arxiv.org/abs/2310.01589).
