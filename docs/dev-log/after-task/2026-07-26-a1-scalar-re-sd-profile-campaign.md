# After Task: Scalar A1 RE-SD profile campaign

## 1. Goal

Diagnose the residual marginal-percentile-bootstrap undercoverage for scalar
Gaussian random-intercept SDs, rule in or down `R = 199` quantile resolution,
and test profile and Wald intervals without altering Arc D, public APIs, or the
association lane.

## 2. Implemented

Added a fail-closed R=999 profile/bootstrap/Wald campaign harness, all-attempt
analysis, deterministic shard manifest, profile endpoint accounting, and an
evidence report. Totoro completed the 3,000-attempt comparison; the report
records the numerical result and deliberately withholds a recommendation.

## 3a. Decisions and Rejected Alternatives

The target is the natural-scale `sd:mu:(1 | g)` in a Gaussian iid
random-intercept model with truth 0.5. Coverage counts all 1,000 outer attempts
per group-count cell. Unavailable intervals count as noncoverage; their count
is retained separately. The profile comparison uses 10 observations/group,
whereas the matched R=199/R=999 resolution diagnostic retained its original
4-observations/group design. We retained the all-attempt denominator, did not
reduce `R`, repin a negative control, introduce a bootstrap correction, or
reinterpret any endpoint clamp. Fisher rejected a profile-first recommendation
despite stronger aggregate calibration because its own directional-miss fence
failed.

## 4. Files Touched

The dated simulation-artifact directory contains the runner, analysis, launch
receipt, protocol, reproducible report, and README. The helper/test contract
now filters only deterministic shard files, so repeated analysis does not
ingest its own CSV outputs. `docs/dev-log/check-log.md` records the completed
evidence and its limits.

## 5. Checks Run

Totoro completed 300 shards / 3,000 rows, with 1,000 unique seeds in each cell,
no matching error logs, all fits converged, and `pdHess = TRUE` throughout.
The analysis verified the completion manifest, row counts, unique keys, and
runner/helper/package-commit labels before calculating coverage. The targeted
testthat contract test and R parser check passed after the idempotence repair.

## 6. Tests of the Tests

The new shard-file selection contract excludes summary CSVs that the former
generic `\\.csv$` selection would have re-ingested on a second analysis run.
The existing contract test also exercises duplicate keys, unavailable intervals,
malformed profile output, and failed profile extraction.

## 7a. Issue Ledger

No GitHub issue or PR was opened, edited, or closed. The campaign is local to
Totoro and its report is intentionally diagnostic-only. Foreign PRs and the
Arc D / association lanes were untouched.

## 8. Consistency Audit

Searched the active artifact directory for stale `held`, `not authorized`, and
one-attempt-per-shard wording. The protocol and README now identify completed
diagnostic evidence, the 10-attempt shard layout, the execution exception, and
the withheld recommendation. Historical smoke and prior after-task records are
left intact because they were true when written. This is internal dev-log prose;
no pkgdown, README, NEWS, capability ledger, formula grammar, or public docs
changed.

## 9. What Did Not Go Smoothly

A launcher-manifest ordering repair led to a restart while the initial launcher
was still alive. Two 100-worker launchers overlapped briefly, breaching the
approved 100-worker cap. Shinichi ratified that table as diagnostic-only and
authorised a clean `g = 10` rerun. The clean 100-worker locked run reproduced
all non-runtime inference/status fields exactly across 1,000 matched seeds and
records the installed package tarball hash.

## 10. Known Residuals

The R=199 conclusion is limited to the two matched original 4-observations/
group cells: tail-resolution is not dominant there. The profile comparison is
limited to Gaussian iid random intercepts with 10 observations/group. It does
not establish a causal split between percentile-boundary behavior and Laplace
refit bias, nor transfer to other families or structured random effects. At 10
groups, 63 profile endpoints reached the parameter-space zero boundary; this
does not decide the blocked Arc D clamp-endpoint contract.

## 11. Team Learning

Fisher found that profile clears aggregate-calibration and availability gates
but fails the predeclared directional-miss fence: upper misses materially exceed
lower misses in every cell. Rose verified data integrity but required the cap
breach and non-cryptographic package-commit label to remain explicit. The
correct outcome is a more informative diagnostic, not a public method change.

## 12. Cross-Product Coverage

No cross-product work was required: the result changes no package behaviour,
public documentation, capability ledger, or API. It does NOT cover REML,
penalties, missingness, aggregation, other families, structured covariance,
Arc D endpoint semantics, or the association engine. The report explicitly
keeps those downstream surfaces out of scope.

## Next Actions

Shinichi ratified the diagnostic table and the clean `g = 10` rerun completed.
Profile-first remains withheld under Fisher's directional-miss fence. Any study
of the remaining one-sided profile and bootstrap failures requires a fresh,
separately approved plan; it is not an Arc D implementation.
