# After-task report — Arc 6 F4 DRAC no-launch runbook

## 1. Goal

Prepare a source-pinned DRAC runbook for the already prepared private F4 runner
without contacting DRAC, staging source, scheduling a job, or running compute.

## 2. Implemented

Added the F4 no-launch runbook.  It identifies the frozen private inputs,
24-shard mapping, source/fixture/manifest checks, retained-all-attempt schema,
quarantine actions, and the later receipt fields that must be named before a
single `sbatch` submission.

## 3a. Decisions and Rejected Alternatives

The runbook contains no scheduler command because the DRAC cluster, account,
resource request, snapshot path, and output root remain unapproved.  A
placeholder is rejected rather than silently becoming an account, path, or
capacity decision.

## 4. Files Touched

- `docs/dev-log/2026-07-27-arc6-f4-drac-no-launch-runbook.md`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

Confirmed that `HEAD` equals the owner-authorized F4b base and re-read the two
required private-engine blob IDs.  Reviewed the local DRAC operating runbook
and passed `git diff --check`.  No remote command was issued.

## 6. Tests of the Tests

This is documentation only.  The runbook delegates seed/schema enforcement to
the already tested F4b runner and does not invoke it.

## 7a. Issue Ledger

Resolved: a named no-launch F4 DRAC runbook.  Deferred: post-runbook SHA,
specific DRAC account/resources, staging, preflight, 24,000 refits, F4 review,
and F5.

## 8. Consistency Audit

The runbook follows the preregistration's 24 cells, 1,000 attempts per cell,
alpha-only private variance path, all-valid primary coverage denominator, and
quarantine policy.  It does not alter the DGP or calibration targets.

## 9. What Did Not Go Smoothly

The F3 smoke supplies no runtime benchmark, and the owner has not selected a
DRAC account or capacity allocation.  The runbook therefore withholds a false
precise `--time`/memory request.

## 10. Known Residuals

No source snapshot, remote output root, account, scheduler request, fit, or
result exists.  F5/public inference is unchanged and unavailable.

## 11. Team Learning

A scheduler command is an execution decision, not documentation.  The source,
account, resources, and output location must be bound together in its approval.

## 12. Cross-Product Coverage

Only the F4 Bernoulli x ordinary-NB2 alpha campaign is described.  No other
association class or public product surface is covered.
