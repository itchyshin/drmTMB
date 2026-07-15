# Structured REML And ADEMP Conversion Gates

## Purpose

This note banks the SC321-SC360 design gates for the structured random-effect
conversion arc. It defines where REML wording is allowed and records ADEMP
designs for q1, q2, and q4 simulations before any calibrated coverage grid is
run.

## REML Scope Gate

REML wording is allowed only for exact-Gaussian rows whose target, route,
estimator, and validation evidence are named. Two native bivariate q2
location-intercept exceptions now meet that rule at `point_fit_recovery`: the
matching labelled fixed-covariance spatial cell and the matching labelled
`relmat(1 | p | id, K = K)` cell with the same supplied `K` and group ordering
in `mu1` and `mu2`. The relatedness cell reuses the existing exact-Gaussian
native-TMB REML engine. Other native q2 REML, native q4 REML, non-Gaussian
REML, broad R bridge REML support, and HSquared AI-REML wording remain out of
scope. In particular, `relmat(..., Q = Q)`, `animal()`, slopes, q4+,
scale-side structure, intervals, and coverage do not inherit the supplied-`K`
q2 claim. Q4 Patterson-Thompson REML is not HSquared AI-REML.

The dashboard gate is
`docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv`. Each row states the
allowed wording, forbidden wording, evidence path, and next gate.

## ADEMP Q1 Design

### Aims

The primary q1 aim is to evaluate point bias, RMSE, finite-fit rate, boundary
rate, and interval availability for single-response structured random effects
on `mu` and `sigma`. A secondary aim is to compare matrix type and signal
strength without mixing bridge or REML claims into native ML status.

### Data-Generating Mechanism

Generate Gaussian single-response distributional-regression data with one
structured random effect. Vary sample size, matrix condition number, random
effect SD, fixed-effect signal, and boundary proximity. Treat `phylo()`,
`spatial()`, `animal()`, and `relmat()` as matrix-origin conditions rather than
one generic structured effect.

### Estimands

The q1 estimands are structured SDs and selected fixed effects for the named
endpoint. Replicate-specific truth must store the matrix digest, endpoint, and
structured type so bridge and native rows can be compared only when the target
matches.

### Methods

Fit native TMB ML first. Direct DRM.jl and R-via-Julia routes enter only after
the q1 parity fixture contracts are executable. REML routes enter only after
exact-Gaussian derivations and route-specific tests exist.

### Performance

Report bias, RMSE, finite-fit rate, boundary rate, interval availability, and
wall time. Failed fits, boundary diagnostics, and unavailable intervals remain
in denominators. A calibrated coverage grid should target coverage MCSE at or
below 1 percentage point, which requires about 500 replicates per calibrated
cell for nominal 95 percent coverage.

## ADEMP Q2 Design

### Aims

The primary q2 aim is to evaluate location-covariance target recovery without
collapsing q2 into q2-plus-q2 or full q4. A secondary aim is to measure
extractor availability for q2 targets separately from interval reliability.

### Data-Generating Mechanism

Generate Gaussian bivariate location models with structured effects on `mu1`
and `mu2`. Vary structured type, matrix condition, sample size, random-effect
SDs, and mean-mean correlation. Keep scale axes absent from the q2 DGP.

### Estimands

The q2 estimands are mean-side structured SDs and one mean-mean covariance or
correlation target. Q2-plus-q2 scale evidence and q4 cross-axis correlations
are separate estimands.

### Methods

Fit native TMB ML first. Direct DRM.jl and R-via-Julia methods are included
only when same-target payloads and reconstruction maps exist. Native REML is a
separate method only for the exact matching labelled fixed-covariance spatial
and supplied-`K` `relmat()` location-intercept cells. The latter has an
independent dense restricted-likelihood oracle and retained 2,400-attempt
recovery evidence, but no interval or coverage evidence. `Q`, `animal()`,
slopes, q4+, scale-side, missing/weighted-pair, and other q2 REML layouts remain
excluded from this ADEMP method set.

### Performance

Report bias, RMSE, finite-fit rate, extractor availability, boundary rate, and
wall time. Failed fits and derived-unavailable targets remain in denominators.
Coverage remains planned until a calibrated grid stores finite intervals and
MCSE for every reported cell.

## ADEMP Q4 Design

### Aims

The primary q4 aim is to evaluate all-four point recovery for structured
effects on `mu1`, `mu2`, `sigma1`, and `sigma2` while keeping direct SD targets
separate from derived correlations. A secondary aim is to audit how often
derived cross-axis intervals are unavailable.

### Data-Generating Mechanism

Generate Gaussian bivariate location-scale data with structured effects on all
four axes. Vary structured type, matrix condition, sample size, direct SD
signals, cross-axis dependence, and boundary proximity.

### Estimands

The direct q4 estimands are four structured SD targets. The six cross-axis
correlations are derived targets and must be stored separately with their own
availability and finite-interval accounting.

### Methods

Fit native TMB ML point routes first. Bridge and REML methods are excluded
until q4 target contracts, reconstruction maps, and same-target parity
fixtures exist. Native q4 REML is not included in the calibrated design until
its exact-Gaussian derivation and tests exist.

### Performance

Report bias, RMSE, finite-fit rate, direct-target availability, derived-target
unavailability, and wall time. Failed fits and non-finite derived intervals
remain in denominators. No q4 interval coverage claim is made until finite
direct and derived interval accounting passes with MCSE.

## Williams Reporting Self-Audit

| Item | Coverage In This Gate |
| --- | --- |
| 1. Aims | Stated separately for q1, q2, and q4. |
| 2. Data-generating mechanism | Written as model conditions before code. |
| 3. Estimands | Direct and derived targets are separated by dimension. |
| 4. Methods | Native TMB ML enters first; only the exact native spatial and supplied-`K` relmat q2 REML cells cross the route-specific point-recovery gate, while bridge and other REML methods remain gated. |
| 5. Performance measures | Bias, RMSE, fit rates, availability, boundary rates, and wall time are named. |
| 6. Software and session details | Deferred to runner implementation. |
| 7. Code availability | Deferred to runner implementation. |
| 8. Workflow reproducibility | Planned through dashboard ledgers and future runner artifacts. |
| 9. Real-data case study | Deferred; Ayumi reply remains parked. |
| 10. Simulation results | Not run in this design gate. |
| 11. Monte Carlo uncertainty | MCSE target is stated before choosing replicate counts. |

## References

- Morris, T. P., White, I. R., & Crowther, M. J. (2019). Using simulation
  studies to evaluate statistical methods. *Statistics in Medicine*, 38,
  2074-2102.
- Williams, D. R., et al. (2024). Transparent reporting items for simulation
  studies evaluating statistical methods. *Methods in Ecology and Evolution*,
  15, 1926-1939.
