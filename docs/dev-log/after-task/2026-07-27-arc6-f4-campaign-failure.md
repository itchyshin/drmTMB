# After Task: Arc 6 F4 alpha Godambe-Wald campaign

## Goal

Evaluate the pre-registered private alpha Godambe-Wald candidate for the
fixed-effect, complete-pair Bernoulli x ordinary-NB2 `associate_pairs()`
intercept route before any public uncertainty exposure.

## Implemented

The approved 24-cell by 1,000-attempt DRAC campaign completed. Its review
retains a fail-closed public boundary: the F4 screen failed, so no `vcov()` or
`confint()` method was enabled.

## Mathematical Contract

The estimand is link-scale `alpha`; the private candidate uses the full staged
Godambe covariance, not conditional stage-2 curvature. Primary coverage uses
all valid-protocol outer datasets, treating an unavailable alpha interval as
non-coverage. Conditional coverage is diagnostic only.

## Files Changed

- `docs/dev-log/2026-07-27-arc6-f4-completion-review.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- this report

## Checks Run

- Authenticated 24 `RUN-COMPLETE.txt` receipts, 24 all-attempt tables, 24,000
  unique `(cell_id, replicate)` rows, and 1,000 rows per cell.
- Confirmed every source receipt records SHA
  `a97aa0930cbfe635886f483cb32baf4e75f74227`, private-engine blob
  `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd`, and fixture blob
  `d36b02b2ad470e641843d4f751ee1c998e6922bf`.
- Recomputed frozen cell summaries from retained all-attempt files with
  `R_PROFILE_USER=/dev/null Rscript --no-init-file /private/tmp/arc6-f4-review.R`.
  Five cells fail primary coverage; all other frozen screens pass.

## Tests Of The Tests

The aggregation asserts the expected 24 files, 24,000 rows, pinned source and
blob values, 24 unique cell/replicate grids, and uses the recorded
`point_available`, `alpha_godambe_available`, and `interval_available` flags
rather than reconstructing status from a fitted object. The five failing rows
were independently checked against their raw all-attempt tables.

## Consistency Audit

The public association boundary remains unchanged: `associate_pairs()` still
returns point association only and public uncertainty methods remain
informative failures. The new limitation wording points to the failed F4
evidence instead of implying that private alpha calibration supports public
intervals.

## GitHub Issue Maintenance

Inspected open issue #680, which records a general, coverage-gated question
about small-sample t calibration for existing package intervals. It is not an
approved association remediation design and was left unchanged. No issue was
opened or changed: the F4 failure is fully scoped to retained evidence and does
not authorize a new remediation arc or public feature.

## What Did Not Go Smoothly

The low-`sigma` cells lose alpha availability through boundary-unresolved or
unstable-sandwich attempts. Because the protocol properly retains those
attempts as primary non-coverage, five cells miss the frozen coverage rule.
The copied receipt packet also lacks a replayable SE/SD bootstrap seed/payload
and per-shard scheduler command/manifest hash; neither changes this coverage
failure, but both should be retained by a future campaign.

## Team Learning

Retained all-attempt accounting distinguished a real availability/coverage
deficit from an apparently acceptable conditional-coverage diagnostic. The
alpha candidate is well centred and its available SE calibrates to empirical
SD, but that is insufficient for public inference when the public interval is
not reliably available. The eta-delta extractor also treated a rowwise private
eta SE as unavailable; eta was descriptive here, but future work must not
mistake this for alpha uncertainty or a completed eta inference path.

## Known Limitations

The only tested F4 alpha Godambe-Wald screen failed. The fixed-effect,
complete-pair Bernoulli x ordinary-NB2 association route remains point-only;
all other association routes and eta intervals remain outside the claim.

## Next Actions

Do not implement F5. A later, separately approved method-design arc may
investigate the low-`sigma`, small-`n` failure mechanism; it must use a fresh
protocol and cannot reclassify or rerun the completed F4 attempts.
