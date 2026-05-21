# Phase 18 Animal/Relmat Q2 Interval-Status Plan

This note decides the first interval-status contract for the known-matrix
`animal()` and `relmat()` q=2 bivariate Gaussian smoke grid. It sits after the
ADEMP sheet and grid writer. The goal is to keep the first exported artifacts
honest: fixed-effect recovery, structured SD recovery, structured correlation,
and residual `rho12` should not be collapsed into one coverage claim.

## Interval Rows

| Estimand row | First interval status | Reason |
| --- | --- | --- |
| `mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x` | Wald, `interval_scale = "formula_coefficient"` | The smoke summariser already records formula-coefficient estimates and standard errors from `summary(fit)$coefficients`. |
| `sigma1`, `sigma2` | `not_requested` for the first interval artifact | The current summary reports public residual scales, but it does not yet store a response-scale standard error or profile target for public `sigma1`/`sigma2`. |
| `animal:sd1`, `animal:sd2`, `relmat:sd1`, `relmat:sd2` | Direct profile target, opt-in only | These are boundary-sensitive variance-component targets. Wald intervals on the public SD scale would look convenient but are not yet justified. |
| `animal:cor`, `relmat:cor` | Direct profile target, opt-in only | Fisher-z Wald intervals need an explicit standard-error source for the structured correlation; until then the fitted-model profile route is the honest interval path. |
| `rho12` | Direct profile target, opt-in only | Residual `rho12` is a different covariance layer from the structured animal/`relmat()` correlation and should keep its own interval rows. |
| Known `A`, `Ainv`, `K`, or `Q` | no interval row | The relatedness matrix is supplied data, not an estimated target. |

## Artifact Contract

The next code slice should add optional interval artifacts to the q=2 grid
writer in this order:

1. Add optional `profile_parameters`, `profile_level`, and `profile_args`
   arguments to `phase18_run_animal_relmat_q2_smoke()`.
2. Use `phase18_profile_interval_columns()` inside
   `phase18_summarise_animal_relmat_q2_fit()` so unrequested rows remain
   visible as `profile.status = "not_requested"`.
3. Add Wald interval CSVs only for rows with finite fixed-effect standard
   errors.
4. Convert profile columns into profile interval, profile coverage,
   interval-evidence, interval-diagnostic, and interval-failure CSVs using the
   existing Phase 18 interval helpers.
5. Keep profile parameters empty by default in CRAN-facing tests. A separate
   opt-in smoke should request only one structured SD, one structured
   correlation, and residual `rho12` before any larger profile grid runs.

## Reporting Rule

Reports may describe q=2 animal/`relmat()` smoke-grid artifacts once aggregate,
replicate, manifest, and failure CSVs exist. They should not report interval
coverage for structured SDs, structured correlations, or residual `rho12` until
the interval-evidence table records how many requested profiles succeeded,
failed, or were not requested. A failed profile is an interval-method result,
not a model-estimation failure and not a coverage miss.

## Failure Ledger

The first interval artifact should still keep these rows outside the fitted
surface:

- pedigree-to-`Ainv` construction;
- structured slopes;
- `sigma` structured effects;
- q=4 location-scale animal/`relmat()` blocks;
- predictor-dependent `corpair()` regressions;
- direct-SD grammar such as `sd_animal*()`;
- non-Gaussian structured effects.

Those rows belong in the failure ledger beside the grid until their own
likelihood, extractor, interval, diagnostic, and recovery gates exist.
