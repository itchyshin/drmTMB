# After Task: AOI-2D3 diagnostic replay claim review

## 1. Goal

Run the owner-authorized, local-only diagnostic replay of a frozen stratified
sample from the retained AOI-2 Bernoulli x ordinary-NB2 fixed-effect campaign.
The purpose was to describe nonexclusive pre-prediction diagnostic triggers,
not to rerun, repair, reclassify, or replace the original point-recovery
campaign. The AOI-2 point-recovery result remains on HOLD.

## 2. Implemented

The immutable sample manifest contains 113 unique formula, sample-size, and
replicate keys: 71 original `boundary_unresolved`, 30 `interior`, and 12
`near_boundary` rows across additive, factor-interaction, mixed,
numeric-interaction, and transformation formulas at n = 360, 720, and 1440.

The local replay completed all 113 dispatches with exit status zero. Every
dispatch records the one pinned replay source SHA
`e9375dbed4243e1e9d9f17b36a7236b29db55685`. The supplied analyzer validated
the manifest-key match and wrote the retained descriptive outputs under
`docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-diagnostic-analysis/`.

The replay description is internally diagnostic only. Of the frozen sample,
66 of 71 originally boundary-unresolved rows replayed as boundary-unresolved;
all 66 carried `score_failure`. Five of those rows replayed as interior. All
30 sampled interior rows replayed as interior. Of 12 sampled near-boundary
rows, 11 replayed as near-boundary and one as boundary-unresolved. Across all
113 rows, the nonexclusive flags counted 66 score failures, 8 multistart
disagreements, 4 convergence failures, and zero hard-parameter-cap,
nonfinite-log-likelihood, weak-curvature, or endpoint-failure flags.

## 3a. Decisions and Rejected Alternatives

The result is a descriptive diagnostic of the frozen stratified sample. It is
not a population estimate, a new recovery study, an estimator change, or a
substitute for the original 3,000-attempt campaign.

Rejected alternatives: treating replay-status differences as corrections to
the original result; pooling this 113-row diagnostic sample into the original
campaign; interpreting a score flag as an exclusive cause; promoting a point
estimate claim; and starting AOI-3 or exposing uncertainty. The retained
original 708 unavailable attempts are not reclassified by this work.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-local-replays/`
  contains the valid completed replay, immutable manifest copy, dispatch, and
  session record.
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-diagnostic-analysis/`
  contains analyzer output: `replay-rows.csv`, `status-match.csv`,
  `trigger-rates.csv`, `decision.txt`, and session information.
- This receipt records the constrained claim review.

The earlier invalid mixed-source-SHA attempt remains preserved separately at
`docs/dev-log/simulation-artifacts/2026-07-31-aoi2d3-local-replays-invalid-mixed-source-sha/`;
it was excluded from this analysis and was not pooled with the valid replay.

## 5. Checks Run

- The frozen manifest has 113 unique formula/n/replicate keys.
- The completed valid replay has 113 dispatch rows, all exit status zero, and
  one pinned replay SHA.
- `tools/summarize-aoi2-diagnostic-replays.R` completed successfully against
  the immutable manifest and valid replay root.
- The analyzer's decision is explicitly `INTERNAL_AOI2_DIAGNOSTIC_ONLY` and
  explicitly calculates no point-recovery, interval, covariance, uncertainty,
  or capability claim.

## 6. Tests of the Tests

The diagnostic summary refuses a manifest/input key mismatch and records the
decision boundary in `decision.txt`. The source-SHA pin was independently
checked in the completed dispatch, and the invalid mixed-SHA prior attempt was
kept outside the analyzer input root. The row-level status table preserves
replay disagreement rather than silently treating original labels as replay
outcomes.

## 7a. Issue Ledger

No issue status, capability-ledger cell, public article, or public API changed.
The outstanding item remains the AOI-2
`HOLD_NO_POINT_RECOVERY_CLAIM` disposition.

## 8. Consistency Audit

This receipt agrees with the AOI-2 consolidation HOLD and the D0-D2 diagnostic
receipt: diagnostics are captured before prediction, trigger flags are
nonexclusive, unavailable results count against all-attempt recovery, and the
association formula/prediction implementation does not license uncertainty.
Lane B `sd()`/profile work, Arc D, foreign association branches, and public
capability surfaces remain untouched.

## 9. What Did Not Go Smoothly

The valid replay was computationally long, particularly in retained n = 1440
cells. The first local attempt had mixed source-SHA provenance and was moved to
its explicitly invalid, retained directory rather than being repaired or
silently combined. An ad-hoc monitor initially assumed homogeneous design
columns across formula classes; the supplied analyzer, which handles the
formula-specific columns, was used for the actual result.

## 10. Known Residuals

This stratified replay does not identify a unique causal mechanism for every
boundary outcome. In particular, score failure is nonexclusive and the sample
is deliberately not a full-population estimate. The original AOI-2 result
therefore remains **HOLD_NO_POINT_RECOVERY_CLAIM**. No standard errors,
covariances, intervals, profiles, `vcov()`, or `confint()` are available from
this work.

## 11. Team Learning

Pre-prediction payload capture makes it possible to distinguish diagnostic
signals from a prediction fallback, but only if the triggering run is tied to
an immutable sample and a single source SHA. Diagnostic replay disagreement is
information to retain, not a reason to rewrite original all-attempt evidence.

## 12. Cross-Product Coverage

This review covers only a stratified retained-seed diagnostic replay for the
Bernoulli x ordinary-NB2 fixed-effect association runner and the five sampled
fixed-effect formula classes. It does NOT cover point recovery, validation of
the full original campaign, uncertainty, covariance calibration, random or
structured association effects, missingness, weights, offsets, REML, new
family pairs, `vcov()`, `confint()`, profiles, or public capability claims.

## Next Actions

Preserve the AOI-2 HOLD and its original retained evidence. A future owner may
use this receipt to decide whether a separately designed point-estimation route
is defensible. AOI-3 requires a distinct authorization for its local smoke and
then (only if it passes) its preregistered DRAC full-refit uncertainty
calibration campaign.
