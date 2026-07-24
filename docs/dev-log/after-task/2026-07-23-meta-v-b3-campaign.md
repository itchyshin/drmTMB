# After Task: `meta_V` B3 retained-evidence campaign

## Goal

Run the separately approved B3 Gaussian known-`V` campaign only after an
authenticated two-cell Totoro smoke, reduce all retained attempts, and close
without an automatic capability claim or CRAN action.

## Implemented

The frozen contract at source commit `001ac983` ran 96 deterministic Totoro
shards of 175 fits (16,800 attempts). The reducer authenticated the 96 shard
receipts, campaign receipt, 11 source hashes, and smoke artifact before writing
the retained summary. The full raw result and reduction directories remain
local; the compact reduction is retained at
`docs/dev-log/evidence/2026-07-23-meta-v-b3-retained-reduction.md`.

## Mathematical Contract

The exact fitted model is Gaussian ML
`bf(yi ~ x + meta_V(V = V), sigma ~ 1)`. Known sampling covariance is input
data; `sigma` is fitted residual heterogeneity. The primary rate is finite and
truth-covering Wald intervals over all 1,200 scheduled attempts, not coverage
conditional on finite intervals.

## Files Changed

The original campaign provenance and compact reductions were retained under
`docs/dev-log/simulation-artifacts/2026-07-22-meta-v-b3-smoke/repeat-001ac983/`
on `codex/meta-v-b3-contract`. Arc 7 B0 deliberately imports only this report
and the compact reduction, never raw results, shard logs, seed maps, or launchers.

## Checks Run

- Totoro smoke receipt: K=12/vector seed 4 retained the required `sigma`
  `[0, Inf]` interval; K=36/dense control had finite intervals for all targets.
- Campaign reducer: 96 receipts, 16,800 manifest rows, and 50,400 parameter
  rows; all 16,800 fit results were `ok`, with zero convergence, Hessian, or
  fit errors.
- The reducer recorded 3,712 `degenerate_zero_infinite` intervals and 46,688
  finite intervals. Its failure ledger had zero rows.
- Fisher and Rose found coherent 96-receipt provenance and an intact
  denominator, but both withheld promotion. The all-attempt `sigma`
  finite-and-covering rate ranged from 0.4117 to 0.8900 in the tested small-K
  boundary domain; conditional-on-finite values cannot replace it.

## Tests Of The Tests

The B3 suite exercised a missing/incorrect approval scope, mismatched host
label, absent receipt, altered completion count, unavailable Totoro, excessive
projected shard time, and transferred smoke approval evidence. The failed first
smoke and failed first campaign launch were retained rather than overwritten.

## Consistency Audit

The campaign retained the route as implemented/tested but tier-unregistered,
with no interval or coverage claim. No reader-facing status, formula grammar,
NEWS, roadmap, or pkgdown wording changed as part of the original campaign.

## GitHub Issue Maintenance

Issue #59 remained the Phase 18 umbrella. No issue comment was posted because
the campaign changed no public status or release tracker.

## What Did Not Go Smoothly

The first smoke failed before fitting because its wrapper did not attach
`drmTMB`. The first formal launch then failed before fitting because a locally
authored campaign receipt referenced a local smoke-artifact path. Both
failed-closed states were retained; the unchanged contract then ran with a
host-local receipt.

## Team Learning

An approval receipt that includes a retained artifact path must be authored on,
or made portable to, the execution host. A hash can authenticate a file while
an inaccessible path still prevents a valid launch.

## Known Limitations

This campaign covers only Gaussian ML, `sigma ~ 1`, and the known-vector/dense
`V` grid. It does not validate REML, profile/bootstrap intervals, `sigma ~ x`,
proportional or misspecified `V`, non-Gaussian meta-analysis, clustered effect
sizes, arbitrary dense covariance, interval feasibility, coverage
certification, or any capability tier.

## Next Actions

Arc 7 B0 must preserve the compact evidence, keep `meta_V()` tier-unregistered,
and make no automatic promotion. A new interval-method arc needs separate
approval and its own design, smoke, and evidence gates.
