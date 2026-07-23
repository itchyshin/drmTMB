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
5. Fisher and Rose must review the exact-SHA contract. Shinichi then gives a
   smoke-only approval; campaign approval is a separate post-smoke decision.

## Contract-hardening status

The branch-local B3 contract now freezes the ordered 14-cell registry, a
16,800-row formal seed map, the fixed Wald call, source-file hashes, runtime
receipt, a 96-by-175 deterministic shard map, and a completion validator. The
formal launcher rejects any replicate count other than 1,200. The two-attempt
smoke is deliberately outside the formal denominator: its K=12 vector boundary
uses fixed seed 4, while its K=36 dense interior control has a separately
declared seed. This removes the earlier error of expecting a generic
master-seed draw to reproduce the known boundary.

This is still **not compute approval**. The contract now has two non-
interchangeable approval receipts. A `smoke` receipt authorizes only the two
diagnostic attempts. A later `campaign` receipt is required for every formal
shard and for reduction; it names Shinichi, records fresh CLEAR Fisher/Rose
verdicts, matches the exact contract fingerprint and source hashes, hashes the
validated retained smoke artifact from which its two timings are read, and
stores the reproducible host decision. The timing smoke itself must be
explicitly labelled `Totoro`; every formal shard must carry the one approved
host label. A self-asserted environment variable alone cannot start the smoke,
a formal shard, or reduction.

## Track B routing after approval

**Primary host: Totoro, only when the frozen rule selects it.** It must be
reachable through its ControlMaster route, have one-minute load below 96, and
have conservative projected shard time at most six hours, calculated as
`1.25 * max(two smoke elapsed seconds) * 175`. It then uses at most 96
independent R workers with `OPENBLAS_NUM_THREADS=1`, deterministic replicate
shards, and one retained result bundle per shard. Start with one boundary and
one interior cell at one replicate; inspect the retained interval artifact and
manifest before scaling to the frozen 16,800 attempts.

**Fallback host: DRAC.** Use a SLURM array if Totoro is unavailable, its load is
96 or higher, or the frozen timing calculation exceeds six hours. Do not pool
Totoro and DRAC results in one denominator. Reduction accepts only 96 unique
formal shard receipts matching the campaign receipt, source hashes, and contract
fingerprint, including the selected host label. Results are diagnostic
operating-characteristic evidence for the exact Gaussian ML, `sigma ~ 1`,
known-`V` cells only.

## Explicit exclusions

This packet does not validate REML, profile/bootstrap intervals, `sigma ~ x`,
proportional or misspecified `V`, non-Gaussian meta-analysis, clustered effect
sizes, arbitrary dense covariance, interval feasibility, coverage
certification, or any capability tier.
