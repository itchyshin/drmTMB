# meta_V B3 decision packet — ADEMP reconciliation

## Decision requested

**B3 status: NO-GO for Track B compute.** This packet freezes the design that a
future approval would authorize; it does not authorize a campaign, a capability
promotion, or a public inference claim.

## What is now executable

`phase18_meta_v_b3_conditions()` defines 14 unique Gaussian ML,
constant-heterogeneity cells. It includes the reproduced boundary condition:
`K = 12`, vector known `V`, `sigma = 0.10`, `sampling_sd = 0.12`, and
`sampling_rho = 0`. The grid has 16,800 planned attempts at 1,200 replicates
per cell.

The simulation summary obtains the residual-heterogeneity interval from
`confint(fit, parm = "sigma", method = "wald")`. A public `[0, Inf]` result is
stored as `degenerate_zero_infinite`; it is not silently replaced by a
symmetric interval reconstructed from a standard error.

## Preconditions for a B3 approval

1. A retained-attempt reporting layer must count every scheduled fit in the
   primary denominator, including errors, non-convergence, missing intervals,
   and `degenerate_zero_infinite` rows. Finite-interval coverage may be
   secondary only.
2. The exact seed map, interval options, diagnostics, and post-smoke amendment
   rule must be frozen before compute.
3. A small-K oracle must compare vector ML to `metafor::rma.uni()` and dense ML
   to `metafor::rma.mv()` for coefficients, heterogeneity variance, and the
   stated likelihood convention.
4. The smoke must prove non-empty artifacts and retain the K=12 boundary status
   before scaling out.
5. Fisher and Rose must review the complete packet; Shinichi must explicitly
   approve compute.

## Track B routing after approval

**Primary host: Totoro.** It has no scheduler queue and is the shortest
wall-clock route for this embarrassingly parallel, CPU-only grid. After the
approved timing smoke, use at most 96 independent R workers with
`OPENBLAS_NUM_THREADS=1`, deterministic replicate shards, and one retained
result bundle per shard. Start with one boundary and one interior cell at one
replicate; inspect the retained interval artifact and manifest before scaling
to the frozen 16,800 attempts.

**Fallback host: DRAC.** Use a SLURM array only if the Totoro load check or the
timing smoke projects an unacceptable completion time. Do not pool Totoro and
DRAC results in one denominator without a predeclared host-stratified merge
rule. Results are diagnostic operating-characteristic evidence for the exact
Gaussian ML, `sigma ~ 1`, known-`V` cells only.

## Explicit exclusions

This packet does not validate REML, profile/bootstrap intervals, `sigma ~ x`,
proportional or misspecified `V`, non-Gaussian meta-analysis, clustered effect
sizes, arbitrary dense covariance, interval feasibility, coverage
certification, or any capability tier.
