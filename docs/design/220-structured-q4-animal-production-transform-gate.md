# Structured q4 Animal Production-Transform Gate

## Purpose

This note defines the next admissible step for the Q-Series animal all-four
one-slope row:

```r
bf(
  mu1 = y1 ~ x + animal(1 + x | p | id, A = A),
  mu2 = y2 ~ x + animal(1 + x | p | id, A = A),
  sigma1 = ~ z + animal(1 + x | p | id, A = A),
  sigma2 = ~ z + animal(1 + x | p | id, A = A),
  rho12 = ~ 1
)
```

This row is q8-shaped in the implementation: the four distributional
parameters each contribute an intercept and slope member, giving eight
structured endpoints and 28 `theta_phylo` correlation coordinates. The current
production path uses TMB's `density::UNSTRUCTURED_CORR_t(theta_phylo)` for the
full q>2 correlation manifold. The existing q4 animal diagnostics are useful
blocker localization, but they are not a production transform.

## Current Evidence

The transform-admission contract is:

- `docs/dev-log/dashboard/structured-re-q4-animal-transform-admission-contract.tsv`

It rejects the current all-free route, fixed soft-cap route, sparse
one-theta route, ridge MAP/penalty route, and ridge-continuation route for
promotion. The ridge-continuation sidecar has zero clean final `lambda = 0`
admission passes across the hard seeds `910101`, `910102`, and `910110`. The
bounded-correlation sidecar is also not a production route because the bounded
rows are cap-saturated. The follow-up partial-Cholesky coordinate diagnostic is
also blocked: the all-free partial-Cholesky route has zero clean admission
passes across the same three hard seeds, with convergence code 1, `pdHess =
FALSE`, large-eta blockers for two seeds, and incomplete direct-SD interval
finiteness. It was an optimizer-layer local diagnostic, not an accepted
lower-level TMB/C++ production transform.

The member review consensus is:

- **Gauss:** another optimizer-layer wrapper around current `theta_phylo` is
  not a production-transform admission experiment.
- **Noether:** a new route can be production only if it is a reparameterization
  of the same full q>2 positive-definite correlation manifold, with matching
  likelihood values and reports.
- **Fisher:** Nibi/Rorqual and DRAC remain held until a local hard-seed
  admission route passes with retained denominators and no cap, ridge,
  large-theta, convergence-watch, or Hessian-blocked rows.

As of 2026-06-29, `tests/testthat/test-phylo-utils.R` also banks the
baseline q=8 objective/report equivalence harness for the current
`UNSTRUCTURED_CORR_t` route. The test exercises the hidden `model_type = 93`
probe at the zero-correlation point and at three finite 28-coordinate
`theta_phylo` vectors, then compares `phylo_q4_corr`,
`phylo_q4_covariance`, log determinant, quadratic form, and objective value
against independent R algebra. This is a baseline for future lower-level
TMB/C++ transform candidates; it is not itself a production transform or a
status promotion.

The first lower-level candidate is now also banked as an internal harness:
`qgt2_corr_parameterization = 1` switches the hidden `model_type = 93` probe to
a partial-correlation Cholesky reconstruction. The focused test checks the
candidate against independent R algebra and against the current
`UNSTRUCTURED_CORR_t` route at the same matched correlation matrices. This
proves the local objective/report path for the hidden candidate at zero and
finite q=8 parameter vectors, but it still does not admit the public animal q4
all-four row.

The hidden candidate has now reached the retained hard-seed local admission
runner and failed the admission gate. The artifact bundle is:

- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/`

For the hard seeds `910101`, `910102`, and `910110`, all three
`partial_cholesky` fits returned convergence code 0, but zero of three had
`pdHess = TRUE`. The runner retained all 24 direct-SD Wald target rows as
`not_run_pdhess_false`; no profile intervals were attempted, no dashboard
sidecar was overwritten, and no Q-Series row was promoted. This is a
Hessian-admission blocker, not a cluster-admission pass.

## Production-Transform Requirement

A production-transform candidate must be an opt-in internal engine route before
it is used for any Q-Series status change. It must satisfy all of these
conditions:

1. The route preserves the intended full q>2 model space or explicitly records
   itself as a constrained diagnostic model. A finite cap such as
   `theta = cap * tanh(eta)` is not equivalent to the current model unless an
   equivalence proof and tests show the same reachable correlation matrices.
2. The likelihood target is unchanged for ML. A smooth reparameterization must
   not add a hidden Jacobian term.
3. The C++ report and the R reconstruction helper must agree on
   `phylo_q4_corr`, `phylo_q4_covariance`, log determinant, quadratic form, and
   objective value at matched parameter points.
4. The public syntax above must remain a full unstructured q>2 route. It must
   not silently become block diagonal, pairwise independent, nearest-PD
   repaired, ridge-penalized, or cap-constrained.
5. The first local admission runner must use the attempted hard-seed
   denominator: no seed replacement after seeing a numerical result.

## First Implementation Slice

The next implementation should be small and internal:

1. Banked: add a non-public TMB/R switch for a lower-level candidate q>2
   correlation parameterization. The current switch is hidden behind
   `qgt2_corr_parameterization` and remains fixed to the production
   `UNSTRUCTURED_CORR_t` route outside tests.
2. Banked: add R helper tests that reconstruct the candidate correlation
   matrix and compare it with the C++ report.
3. Banked: add objective-equivalence tests against the current
   `UNSTRUCTURED_CORR_t` route at zero and at finite q=8 parameter vectors,
   with penalties off.
4. Banked and blocked: wire the hidden `partial_cholesky` route into the local
   hard-seed admission runner for `910101`, `910102`, and `910110`. The runner
   preserves attempted denominators and reports `pdhess_admission_blocked`
   because all three retained fits had `pdHess = FALSE`.
5. Next: diagnose why the equivalent lower-level route still gives a
   non-positive-definite Hessian under the public all-four fit before any new
   transform candidate, Nibi/Rorqual admission job, or coverage design.

The local hard-seed admission pass condition is strict: all three seeds must
have convergence code 0, `pdHess = TRUE`, finite `sdreport()`, finite positive
direct SD estimates for all eight targets, finite Wald and profile direct-SD
intervals, finite positive fixed-effect covariance diagnostics, maximum
unpenalized gradient at most `1e-3`, and no cap saturation, optimizer-layer
ridge penalty, large-theta or large-eta row, convergence-watch row, or
Hessian-blocked multi-coordinate row.

## Cluster Gate

Do not use Nibi, Rorqual, Totoro, FIIA, or DRAC for this row until the local
engine design and hard-seed admission runner pass. The current hidden
`partial_cholesky` hard-seed artifact did not pass because `pdHess = FALSE` for
all three retained seeds. After a future local pass, Totoro/FIIA may be used
for a small retained-denominator smoke if reachable. Nibi/Rorqual are admission
hosts only after that smoke passes. DRAC coverage is still a later
coverage-contract problem and is not authorized by this design gate.

## Forbidden Claims

This gate does not promote any Q-Series row. Do not describe this work as q4
or q8 `inference_ready`, `supported`, interval reliability, coverage, q4 REML,
REML, AI-REML, derived-correlation interval support, broad bridge support,
production support, or public support. The correct public status remains:
animal q4 all-four admission is blocked on lower-level TMB parameterization
design.
