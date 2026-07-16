# Beta phylogenetic q1 PR 1: disjoint-seed provenance repair

**Status:** predeclared before smoke, pilot, or certification results

**Purpose:** rerun the exact frozen `m = 4` addendum with genuinely independent
DGP seeds after discovering that its offset schedule reused 1,197/1,200 seeds
from the original `m = 2` campaign

**Claim ceiling:** `point_fit_recovery`

## What this repair changes

The first addendum set its master seed to `2026071602` but formed each DGP seed
as `master + 100000 * cell_number + replicate`. The original master differed
by one, so 399/400 numeric seeds overlapped within each of the three `g` cells.
The addendum remains an immutable HOLD, but it is not fresh independent
evidence.

This repair changes only seed construction. It preserves the `beta()` DGP,
truth, random coalescent tree generator, formula, native-TMB ML/Laplace
estimator, robust optimizer, `m = 4`, `g = {64,256,1024}`, 400 attempts per
cell, retained denominator, target scales, and every decision threshold. It
does not rescore the old campaigns on raw `tau`, alter a threshold, add a
comparator, or implement direct `sd()` regression.

## Frozen source and model

The engine source is pinned to the implementation at
`b6f74622d5c1041e438d7ac8b1ce654a40a55bc3`. Later evidence-only commits are
allowed only while these Git tree identities remain unchanged:

```text
R/   6908d26231d0133020cdf71d11b022898b33bba3
src/ 5e385ee36b910f907c807c5d5c3767b34e22a373
```

For observation `i` in species `s(i)`:

```text
y_i | a ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = beta_0 + beta_x x_i + a_s(i)
log(sigma_i) = gamma_0 + gamma_x x_i
phi_i = sigma_i^(-2)
a_tip ~ Normal(0, tau^2 A), tau = exp(lambda)
```

Family `sigma` controls conditional Beta precision; latent `tau` is the
constant SD of the phylogenetic `mu` effect. They remain separate targets.

## Frozen schedules

All repair schedules use `sample.int(.Machine$integer.max, ..., replace =
FALSE)` after freezing `RNGkind()` to
`Mersenne-Twister/Inversion/Rejection` and making one `set.seed()` call. The
runner restores the caller's RNG state and kind. The committed certification
design is authoritative; every repair mode must regenerate and authenticate it
before the first fit.

| Phase | Mode | Master seed | Attempts | Role |
| --- | --- | ---: | ---: | --- |
| local and Totoro read-back smoke | `repair_smoke` | 2026071629 | 3 | one fit per cell; never pooled |
| Totoro abort-only pilot | `repair_pilot` | 2026071630 | 30 | ten fits per cell; never pooled |
| certification | `addendum_repair` | 2026071631 | 1,200 | decision denominator |

The certification table has SHA-256
`cfd025e7280ff30db4d95bcdf86da48c251080d516ba1324e80d88681138676a`.
It contains 1,200 unique seeds and has zero overlap with the original `m = 2`
design, the invalid `m = 4` design, the repair smoke, or the repair pilot. The
seed-audit SHA-256 is
`b9e8b02eec3ef2e562b1eeaf2c5591af976ef3ae27c00bdabe5d53bc47130bd6`.

The runner must abort before the first fit if `R/`, `src/`, the runner, or the
frozen design is dirty or untracked; any authenticated prior artifact is
missing or changed; either prior design is malformed; any current seed is
duplicated; any prior/sibling overlap is nonzero; or the generated
certification grid differs from the committed table. Each output records the
exact Git head, source-tree identities, runner and design SHA-256 values, RNG
kind, and package version.

## Unchanged decision gates

The repair passes only if all of these inherited addendum gates pass:

1. exactly 1,200 uniquely keyed attempts are retained;
2. `g = 256` and `g = 1024` each have convergence rate at least 0.95 and
   `pdHess` rate at least 0.90;
3. at both certification cells, absolute mean bias is at most 0.10 for
   `beta_mu_x`, `beta_sigma_x`, and internal `log_tau`; and
4. RMSE for each of `beta_mu_intercept`, `beta_mu_x`,
   `beta_sigma_intercept`, `beta_sigma_x`, and `log_tau` does not materially
   worsen from `g = 256` to `g = 1024`, allowing one bootstrap MCSE of the
   difference.

Every error, warning, nonzero convergence code, non-positive-definite Hessian,
gradient, and boundary flag remains in the attempted denominator. The pilot
may abort certification but may not change the design, target, threshold,
optimizer, or seed schedule.

The original `m = 2` HOLD and earlier `m = 4` HOLD remain visible regardless
of this result. Seed overlap with the `m = 2` campaign invalidates the earlier
claim of cross-campaign independence, but it does not invalidate the 1,200
unique draws as evidence for the `m = 4` estimand. Therefore the disposition is
frozen before the repair result:

- repair HOLD means HOLD;
- repair PASS is pooled with the earlier `m = 4` block, giving 800 attempts per
  cell and 2,400 total; and
- promotion requires both the repair block and this pooled evidence to pass
  every unchanged bias, quality, denominator, and RMSE gate. A repair PASS with
  a pooled HOLD is conflicting/inconclusive, not promotion evidence.

Both block-specific results and the pooled result must remain visible. Bias
MCSE is reported beside each result; a near-threshold PASS is not described as
robust. Only a final promotion PASS can support the exact ML q1 Beta
phylogenetic-location prerequisite under the tested `m = 4` information
regime. Any other result blocks PR 1 promotion and PR 2.

## Execution order

1. Commit this plan, runner, tests, design, and seed audit.
2. Obtain independent Noether, Fisher, and Rose review of the provenance
   repair; no raw-`tau` redesign is part of this run.
3. Run focused runner and Beta tests locally.
4. Run and read back the three-row smoke locally and on Totoro.
5. Run and inspect the 30-row Totoro pilot without changing the contract.
6. Only then run the 1,200-attempt certification on Totoro with at most 32
   workers and BLAS threads pinned to one.
7. Import every compact artifact verbatim, verify hashes and denominators, and
   retain the result whether PASS or HOLD.

No simulation runs on GitHub Actions and no campaign output becomes a GitHub
Actions artifact.
