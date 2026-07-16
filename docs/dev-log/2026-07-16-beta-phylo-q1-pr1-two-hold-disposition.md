# Beta phylogenetic q1 PR 1: two-HOLD disposition

**Date:** 2026-07-16

**Branch:** `codex/beta-phylo-q1-constant-sd`

**Implementation head tested on Totoro:**
`b6f74622d5c1041e438d7ac8b1ce654a40a55bc3`

**Claim status:** no capability-ledger promotion

## Outcome

The exact ML univariate `beta()` q1 phylogenetic-location implementation is
mechanically coherent: independent `dbeta()` and augmented-GMRF calculations
match the joint TMB objective at a displaced full parameter vector, finite
differences match the AD gradient, and extraction and prediction decomposition
tests pass. Both predeclared recovery campaigns nevertheless returned **HOLD**.

The first campaign used two observations per species. It retained 1,200/1,200
attempts and failed the `g = 256` absolute mean log-`tau` bias gate at `0.5203`
versus `0.10`. Its `g = 1024` value was `0.0888` and passed.

The separately predeclared addendum changed only within-species replication
from `m = 2` to `m = 4` and used a different master seed. It also retained
1,200/1,200 attempts, with convergence code zero for every fit. It reduced the
`g = 256` absolute mean log-`tau` bias to `0.2470`, but this still failed the
same `0.10` gate. Its `g = 1024` value was `0.0618` and passed. All fixed-slope
bias gates and all RMSE non-increase gates passed in both campaigns.

A later complete seed-set audit found that the offset schedules share
1,197/1,200 numeric DGP seeds. The `m = 4` HOLD remains valid as a result from
its frozen schedule, but it is not independent confirmation of the original
campaign. The separately predeclared disjoint-seed repair repeats the exact
`m = 4` contract and gates before any raw-`tau` redesign is considered.

## Diagnostic interpretation

The moderate-tree log-scale mean is affected by lower-boundary estimates, but
the frozen retained-denominator verdict does not depend on how those fits are
described after the fact. In the `m = 4, g = 256` cell, 3/400 fits were
boundary-flagged; excluding them descriptively still gives mean log-`tau` bias
of `-0.1683`. Raw-`tau` bias (`-0.0300`) and median log-scale bias (`-0.0986`)
are informative diagnostics, not substitutes for the predeclared mean
log-scale target.

The combined evidence supports three statements only:

1. fixed `mu` and family-`sigma` slopes recover over the tested grids;
2. latent phylogenetic `tau` recovery improves with both species count and
   within-species replication and passes at `g = 1024` in both scheduled
   campaigns; these campaigns are not independent because 1,197/1,200 DGP
   seeds overlap;
3. neither frozen ladder authorizes the planned `point_fit_recovery` ledger
   promotion at moderate `g`.

Family `sigma` remains distinct from latent `tau`: `phi_i = sigma_i^(-2)`
controls the conditional Beta likelihood, whereas `tau` is the constant SD of
the phylogenetic location effect on the logit-mean scale. No
`sd(species, level = "phylogenetic")` regression was implemented or tested.

## Required decision before continuing

Do not open PR 1 as a recovery-grade admission and do not begin PR 2 under the
current goal. The evidence-valid choices are:

- stop the admission, revert the implementation, and retain the design and
  two HOLD artifacts as a documented negative result; or
- approve a narrower, scientifically justified high-information PR 1 goal and
  freeze its confirmation design before any new compute. Such a redesign must
  state the minimum species/replication regime in the claim and cannot rename,
  replace, or relax either existing HOLD.

A diagnostic-only public admission is not recommended because PR 2 depends on
trustworthy recovery of the constant latent SD prerequisite.
