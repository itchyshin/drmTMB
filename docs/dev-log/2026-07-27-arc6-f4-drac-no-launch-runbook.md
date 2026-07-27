# Arc 6 F4 DRAC no-launch runbook — Bernoulli x ordinary-NB2 alpha

**Status:** prepared under the owner's no-launch authorization on base source
`4fcd6dc0531d148f97194a31101c22b64e167951`.  This document does not authorize
an SSH connection, staging, `sbatch`, a model fit, or F5/public inference.

## Purpose and fixed scope

This is the future execution packet for the fixed-effect ML, complete-pair
Bernoulli x ordinary-NB2 route only:

```r
associate_pairs(binary_fit, nbinom2_fit,
  kernel = latent_normal(), association = ~ 1)
```

Its only candidate inferential quantity is link-scale `alpha` with the private
`drm_pair_general_eta_sandwich()` alpha covariance and 95% alpha Wald
endpoints.  It excludes all other pairs, association slopes, eta intervals,
random/structured effects, missingness, weights, offsets, REML, `rho12`, F5,
and public API work.

## Frozen local inputs

The campaign receipt must pin the post-runbook commit SHA, which is deliberately
not guessed in this no-launch document.  At the authorized F4b base, the
private-engine and fixture blobs are:

| Input | Required Git blob |
| --- | --- |
| `R/associate-pairs-sandwich.R` | `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` |
| `tests/testthat/test-associate-pairs-staged-sandwich.R` | `d36b02b2ad470e641843d4f751ee1c998e6922bf` |
| private runner | `tools/run-arc6-bernoulli-nbinom2-f4-private.R` |
| frozen contract | `docs/dev-log/2026-07-27-arc6-f4-preregistration-review.md` |

The runner's `f4_seed_manifest()` must reproduce 24 cells and exactly 24,000
rows.  Array task `k` maps to cell `f4-c%02d`, `k = 1,...,24`; it must retain
replicates `1,...,1000` with seed `2026072000 + 100000*k + r` unchanged.

## Required execution receipt — must be filled before launch

The owner must supply, in one later approval:

1. the full post-runbook source SHA;
2. this exact runbook path;
3. a real DRAC cluster and account, for example `rorqual` plus `def-<pi>` or a
   confirmed RAC account;
4. the immutable remote source-snapshot path and remote output root;
5. per-task `--time`, `--cpus-per-task`, and `--mem` after a documented capacity
   decision; and
6. authorization for exactly one `--array=1-24` submission, with no retry,
   resubmission, top-up, or F5/public exposure.

An approval with placeholders such as `<SHA>`, `<path>`, or `<account>` is not
an executable receipt.

## Preflight sequence

All checks below are performed before a fit.  A failure quarantines the campaign
instead of becoming a dropped attempt or an eligibility exception.

1. Locally confirm a clean checkout and the exact approved SHA.
2. Create an immutable source snapshot from that SHA; never stage a dirty tree.
3. On the execution host, before loading the package, verify the snapshot's
   `git rev-parse HEAD` and both required blobs above.
4. Use the private runner to write and validate the seed manifest.  Verify 24
   cells, 1,000 rows per cell, 24,000 total rows, and no duplicated seeds.
5. Allocate one array element per cell.  Each element writes to a distinct,
   initially absent shard directory; it may not overwrite a prior shard.
6. Load the documented R/TMB dependency route and prove that `drmTMB` resolves
   from the source snapshot, not a user library or installed release.
7. Write source SHA, blob hashes, manifest hash, package/session information,
   scheduler job/array identifiers, and the exact command into every shard
   before its first attempt.

## Shard and all-attempt contract

Each shard calls only the runner's private `f4_run_attempt()` path.  Every seed
produces one all-attempt status row with the schema frozen in
`f4_status_columns`; a terminal margin, association, rectangle, sandwich,
delta, or interval failure remains a row.  An unavailable interval is retained
as primary non-coverage over valid-protocol attempts.  Near-boundary and
boundary-unresolved association results are unavailable points, even when an
internal coefficient exists.

Do not use conditional association curvature, `eta`, `eta_se`, `vcov()`, or
`confint()` as F4 uncertainty inputs.  Do not change starts, tolerances, seeds,
the grid, or status schema.  Do not stop a cell early.

## Stop and quarantine actions

| Condition | Required action |
| --- | --- |
| source/blob/fixture/seed/DGP/status-schema mismatch | Stop further array work, retain written rows, mark campaign quarantined, return for owner decision. |
| ordinary terminal attempt failure | Retain the terminal row and continue with the next assigned seed. |
| infrastructure interruption or resource exhaustion | Retain the evidence and return; no retry or scheduler resubmission is authorized. |
| all 24 shards complete | Preserve all raw rows and metadata for Fisher, Noether, and Rose; do not calculate a public claim or begin F5. |

## Post-campaign evidence boundary

The completion panel receives all raw per-attempt rows, shard metadata,
manifest/source hashes, and summaries with the frozen point, Godambe, interval,
all-valid primary-coverage, and MCSE denominators.  Only that panel can return
a PASS/FAIL F4 verdict.  A PASS is still not a public `vcov()`/`confint()`
decision; F5 requires a separate named approval.
