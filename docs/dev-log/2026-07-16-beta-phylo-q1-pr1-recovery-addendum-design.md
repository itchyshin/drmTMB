# PR 1 Beta phylogenetic q1 recovery: replication addendum

**Frozen:** 2026-07-16, after banking the original campaign as HOLD and before
running this addendum  
**Estimator:** unchanged native R/TMB ML implementation  
**Claim ceiling:** `point_fit_recovery`

> **Provenance erratum (found 2026-07-16 after the HOLD was banked):** the
> offset seed schedule below reused 1,197/1,200 numeric DGP seeds from the
> original campaign. The statement that no original seed was reused is false.
> This addendum remains an immutable HOLD but is not independent evidence. The
> exact-gate disjoint-seed repair is separately predeclared in
> `docs/dev-log/2026-07-16-beta-phylo-q1-pr1-disjoint-seed-repair-plan.md`.

## Why an addendum is needed

The original `m = 2` campaign retained all 1,200 attempts but failed its
predeclared `g = 256` mean log-phylogenetic-SD bias gate. The failure arose
from a lower-boundary tail: 9/400 `g = 256` fits were boundary-flagged. The
fixed slopes recovered cleanly, all RMSE trends improved, and the `g = 1024`
log-SD gate passed. The original gate and HOLD verdict remain unchanged.

This addendum varies only within-species replication. It tests the specific
diagnosis that two observations per species do not reliably separate Beta
sampling variability from the latent phylogenetic location SD at moderate
tree size.

## Frozen DGP and grid

Keep the original DGP, truths, tree generator, optimizer, retained-denominator
rules, and seed construction. Change only `m` from 2 to 4. Run 400 replicates
for each `g = 64, 256, 1024`: 1,200 new attempted fits. Use master seed
`2026071602`. The contemporaneous no-reuse claim was later found false; see
the provenance erratum above.

Run the same one-local-fit, one-remote-replicate-per-cell, then full-campaign
ladder on Totoro with at most 32 workers and BLAS threads pinned to one. Retain
every fit error, convergence code, Hessian status, warning, gradient, and
boundary flag. Never use GitHub Actions for this campaign.

## Predeclared addendum gates

The addendum passes only if:

1. all 1,200 uniquely keyed attempts are retained;
2. both `g = 256` and `g = 1024` have at least 95% convergence and 90%
   `pdHess`;
3. in both of those cells, absolute bias is at most 0.10 for `beta_mu[x]`,
   `beta_sigma[x]`, and `log(tau)`; and
4. RMSE for every named target does not materially worsen from `g = 256` to
   `g = 1024`, allowing one bootstrap MCSE of the difference.

If this addendum passes, PR 1 may claim `point_fit_recovery` for the exact ML
q1 Beta phylogenetic-location cell under the tested information regime, while
prominently retaining the `m = 2, g = 256` finite-information limitation. It
still supports no interval, coverage, REML, direct-SD, or broad-family claim.
