# mc-0653's fixture is cluster-starved, and 64 pairs repairs it

**For:** whoever runs the Prong B interval campaign. mc-0653
(`zi_nbinom2` × `phylo_interaction` × `sigma` q1) was named a promotion blocker
because its profile can return `profile_failed`. This note says why, and what to
change. It does **not** change the fixture — see "What this note does not do".

## The defect

At the fixture's current design the variance component collapses to the lower
boundary:

```
np npo ne  pairs    n     sd_hat  conv  pdHess   truth   rel.err
 4   4 18     16  288  4.953e-05     0    TRUE    0.60   -99.99%
```

The fit reports `convergence = 0` and `pdHess = TRUE` while `sd_hat` is five
orders of magnitude below the generating value. That combination is the reason
this survived as point-fit evidence: nothing in the fit's own status flags it.
It is also why `pdHess` is a want and not a gate.

## Why — reused, not re-derived

This is a known, measured phenomenon in this project's own evidence base, not a
new mystery. The cross-repo note *"Per-cluster information starvation as an
explanation for blocked/failing variance-component cells (drmTMB × gllvmTMB)"*
records it for the scale-side phylogenetic case: a per-species dispersion "has
no within-species replication to separate it from residual noise, so the
likelihood is nearly flat in that direction; plain ML can diverge", with a
documented floor of `n_each >= 5, n_tip >= 150`.

mc-0653 has **16 pairs**. Three things compound:

1. the variance component sits on the NB2 **dispersion**
   (`size = exp(-2 * log_sigma)`), which carries far less per-cluster
   information than a mean;
2. 4 plants x 4 pollinators gives only 16 clusters to estimate an among-pair SD;
3. 20% structural zeros remove a fifth of the rows that carry dispersion signal.

The estimand needs within-cluster replication *and* enough clusters. It had
neither margin.

## The ladder

One seed per rung, `n_each = 18`, `sd_pair = 0.60`. Tree sizes must be powers of
two (`phylo_interaction_balanced_tree` enforces `log2(n_tip) == floor(log2(n_tip))`).

| pairs | n | sd_hat | rel. error |
|---|---|---|---|
| 16 | 288 | 4.95e-05 | -99.99% |
| 32 | 576 | 0.3485 | -41.9% |
| 64 | 1152 | 0.5346 | -10.9% |
| 128 | 2304 | 0.5504 | -8.3% |
| 256 | 4608 | 0.4783 | -20.3% |

**Do not read a floor off this table.** 256 scoring worse than 128 is single-seed
Monte Carlo noise, not a reversal — which is exactly why the rungs below were
re-run with five seeds before any recommendation.

## Five-seed recovery at the candidate rungs

Seeds 2026073001-2026073005, `n_each = 18`:

| design | pairs | n | mean sd_hat | mean rel. err | sd | MCSE | range |
|---|---|---|---|---|---|---|---|
| 8 x 8 | 64 | 1152 | 0.5901 | **-1.64%** | 0.0550 | 0.0246 | [0.535, 0.665] |
| 16 x 8 | 128 | 2304 | 0.5964 | **-0.61%** | 0.0738 | 0.0330 | [0.502, 0.671] |

Both bracket truth; both means sit inside one MCSE of it. All 10 fits converged
with `pdHess = TRUE` and none collapsed. The single-seed -10.9% and -8.3% figures
above were noise.

## The profile works at 64 pairs

Computability is a separate question from recovery, and computability is what
failed. Re-tested at 8 x 8, including the exact `ystep = 0.5` spelling that
returned `profile_failed` / `nonfinite_interval` at 16 pairs:

```
seed 2026073001  ystep=dflt  status=profile  [0.3796, 0.7432]  covers 0.60  msg=ok
seed 2026073001  ystep=0.5   status=profile  [0.3799, 0.7431]  covers 0.60  msg=ok
seed 2026073002  ystep=dflt  status=profile  [0.3899, 0.7319]  covers 0.60  msg=ok
seed 2026073002  ystep=0.5   status=profile  [0.3900, 0.7318]  covers 0.60  msg=ok
seed 2026073003  ystep=dflt  status=profile  [0.4958, 0.8875]  covers 0.60  msg=ok
seed 2026073003  ystep=0.5   status=profile  [0.4959, 0.8873]  covers 0.60  msg=ok
```

Finite, ordered, `msg = ok`, no `near_sd_boundary`, no `nonfinite_interval`, and
all six bracket the generating value. The failure mode is gone at this design.

## Recommendation

Run mc-0653's campaign at **8 x 8 = 64 pairs, `n_each = 18`** (1152 rows).
128 pairs buys a slightly better centre for double the rows and, on five seeds,
no better MCSE — not worth 2x the compute per seed.

## What this note does not do

It does **not** edit `new_zi_nbinom2_sigma_phylo_interaction_data()`'s defaults.
Changing them would silently re-scope mc-0653's existing point-fit evidence,
which was produced at 16 pairs, and that is a campaign-arc decision with a ledger
consequence — not a drive-by fixture edit. The existing test at
`tests/testthat/test-phylo-interaction.R:559` asserts classification only and
still passes unchanged.

Six seeds of profile evidence is also not a coverage claim. This shows the
failure mode is removed at 64 pairs; the campaign's own ten-clause contract
(>= 5 seeds, per-seed truth-bracketing, independent location review) is what
would earn `interval_feasible`.

## Reproduce

```
Rscript --no-init-file /private/tmp/mc0653_ladder.R \
  'expand.grid(seed=2026073001:2026073005, np=8, npo=8, ne=18)[,c("np","npo","ne","seed")]'
```
Helpers are sourced from `tests/testthat/test-phylo-interaction.R` above its
first `test_that()`; the fit is
`bf(count ~ x, sigma ~ phylo_interaction(1 | plant:pollinator, tree1 =, tree2 =), zi ~ 1)`
with `family = nbinom2()` — note `zi ~ 1` in the formula rather than
`family = zi_nbinom2()`, which is what makes it model type `zi_nbinom2`.
