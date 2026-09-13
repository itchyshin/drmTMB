# OU v1 Complete — G0 through G14 checkpoint

## Status

**LANE: START A FRESH TASK.** OU v1 is paused after the first decision-bearing
calibration. The frozen census and the G14 evidence runner are complete; the
planned G15 campaign is not authorised to launch because the G14 result does
not support rate-recovery claims.

## Durable baseline

- Worktree branch: `codex/ou-v1-complete-20260912`.
- Base: completed R1 commit `501fb3ae4`; G0 census commit `5185b8d13`.
- Frozen manifest: `docs/design/264-ou-v1-capability-manifest.csv`, 29 rows.
  It includes the currently supported Gaussian missing-response BM row (G16),
  so that row cannot vanish from the programme.
- Correlated OU correction: for unequal diagonal rates, stationary covariance
  must satisfy \(AS+SA^\top\succeq0\). A future correlated slice must use the
  diffusion-correlation parameterisation recorded in the companion manifest
  note; it cannot reuse BM's correlation switch.

## Completed gates

- **G0:** committed census verifier passes.
- **G1:** the G14 runner writes trees, generated data/fields, full starts and
  attempts, selection/diagnostic tables, checksums, and source provenance.
- **G2:** independent dense/root-edge oracle and native objective, gradient,
  Hessian, and named mutation suite pass.
- **G3:** local calibration retained all 54 starts: 16 ordinary and two
  negative-control tasks, each from three fixed starts.

## G14 inference verdict

The clean-source receipt is at `docs/dev-log/evidence/ou-v1-g14/` and is
verified by `Rscript tools/verify-ou-v1-g14.R --local`.

- All 16 ordinary tasks had one selected qualified fit; only one of the two
  deliberately weak controls did.
- Yet the ordinary selected-fit median absolute log-rate error was 0.593 for
  `alpha_mu` and 1.712 for `alpha_sigma`, versus the proposed G15 bar
  \(\log(1.5)\approx0.405\).
- Warnings and boundary fits remain in `attempts.csv`; they were not replaced
  or omitted.

Fisher's independent verdict is **NO-GO** for the fixed 1,440-attempt G15
design: numerical qualification is not rate recovery. This is an evidence
failure affecting the promised broad OU v1 status, so the plan's stop rule
applies. Do not start Totoro rehearsal/campaign, provider generalisation, or
broader grammar from this evidence.

## Smallest next decision

Approve (or revise) an **R2 information preflight** before resuming:

```text
2 ordered rate pairs × 5 independent tree-plus-field seeds
× 128 species × 12 observations/species × 3 starts
= 30 retained fits
```

It must retain all failures; report availability plus median and maximum
absolute log-rate error separately for both rates; and state explicitly that
the tested amplitude is only `sd_u = 0.45`, `sd_v = 0.25` unless amplitudes
are varied. Estimate it first; it needs local/Totoro routing approval if the
measured projection exceeds 30 minutes.

## Resume commands

```sh
cd /private/tmp/drmTMB-ou-v1-complete
git status --short
Rscript tools/verify-ou-v1-census.R --committed
Rscript tools/verify-ou-v1-g14.R --local
Rscript tools/verify-ou-v1-oracle.R --independent
```

Then create a fresh worktree and a new R2 ledger/lease. Do not amend the
frozen v1 census or erase the G14 receipt.
