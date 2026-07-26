# After Task: Scalar A1 ML-versus-REML attribution campaign

## 1. Goal

Run the approved, paired scalar-A1 Totoro campaign and determine whether REML
materially reduces profile directional-miss asymmetry without widening the lane.

## 2. Implemented

Added an isolated, lock-protected launcher, final paired-decision analyser,
execution receipt, and result report.  Totoro completed all 3,000 paired outer
datasets (6,000 estimator rows).

## 3a. Decisions and Rejected Alternatives

REML is a material contributor at 10 and 25 groups, not at 50, by the frozen
paired rule.  This is an estimator-centre attribution result, not a public
interval recommendation.

## 4. Files Touched

Changes are confined to the scalar-A1 simulation-artifacts directory, its
factual check-log entry, this report, and the existing plan/actual record.

## 5. Checks Run

Local shell syntax and R parsing passed.  A clean three-cell remote smoke under
the pinned library passed.  Totoro produced 300 raw shards, zero matching error
logs, complete key-grid accounting, and hash-linked summaries.  Focused
contracts passed before launch.

## 6. Tests of the Tests

The key-grid contract rejects missing scheduled attempts.  The paired analysis
stops if ML and REML keys are not aligned; a row-name comparison artefact was
caught and repaired before the deterministic final analysis.

## 7a. Issue Ledger

No issue was opened.  The first launcher failed before output because an old
Totoro R library took precedence; `R_LIBS` plus `--vanilla` repaired that
provenance failure before the successful run.

## 8. Consistency Audit

The conclusion is limited to scalar Gaussian iid random-intercept SDs.  It
does not call the mechanism Laplace bias, alter Arc D, or change a public API,
default, ledger tier, or interval wording.

Fisher confirmed the frozen rule classifies 10 and 25 groups as material and
50 groups as non-material; Rose confirmed the hash-linked diagnostic closeout.

## 9. What Did Not Go Smoothly

The campaign completed before a post-launch poll could sample peak workers.
The lock and `xargs -P 100` cap are retained and verified mechanically, but
the receipt explicitly does not claim a measured peak.

## 10. Known Residuals

The raw results remain on Totoro.  A future follow-up may investigate why the
REML effect is not material at 50 groups and whether profile geometry remains
the residual source of directional misses.

## 11. Team Learning

An isolated R library requires `R_LIBS` and `--vanilla`; `R_LIBS_USER` did not
override Totoro's pre-existing user library in this environment.

## 12. Cross-Product Coverage

This arc does NOT cover Arc D endpoint semantics, association, #846's private
engine, bootstrap correction, structured or non-Gaussian random effects, or a
public profile-first recommendation.

## Next Actions

Start a fresh scalar-intervals design arc only after Shinichi chooses whether
to investigate the remaining profile geometry/boundary mechanism.  Do not
re-run this campaign merely to obtain a directly sampled peak-worker count.
