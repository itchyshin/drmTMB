# After Task: staged-eta bootstrap campaign stop

## Goal

Close the staged Bernoulli × ordinary-NB2 full-refit parametric-bootstrap
campaign after the owner judged its multi-day cost disproportionate to a
developer-only inference feature with no approved public interface.

## Implemented

The campaign was stopped, not completed. The pending Fir recovery array was
cancelled and the Totoro dispatchers and their staged-eta runners were
terminated. The recurring two-hour monitor was deleted. No source code,
estimator, simulation design, or completed output was deleted.

## Mathematical Contract

The stopped study still concerns only the sampling distribution of the
two-stage plug-in association-link estimator \(\hat\alpha\) for literal
Bernoulli × ordinary-NB2 complete pairs. It does not establish a standard
error, Wald interval, profile interval, `confint()` method, recovery, or
coverage claim. Conditional stage-2 curvature remains unsuitable because it
omits fitted-margin uncertainty and cross-stage covariance.

## Files Changed

- `docs/design/240-arc6-staged-eta-uncertainty-followup.md`
- `docs/dev-log/simulation-designs/2026-07-24-staged-eta-full-refit-bootstrap/README.md`
- `docs/dev-log/2026-07-24-staged-eta-full-refit-bootstrap-ultra-plan.md`
- `docs/dev-log/check-log.md`
- this report

## Checks Run

Remote stop verification found zero active staged-eta runners and zero
dispatchers on Totoro. The Fir recovery job was cancelled. The campaign monitor
was deleted. The deployed Totoro runner and bootstrap helper SHA-256 values
matched the local approved source before closeout. A final focused local check
passed 20 staged-bootstrap and 69 existing Bernoulli × NB2 expectations;
`git diff --check` passed.

## Tests Of The Tests

No code changed in this closeout, so no new test was required. The existing
focused staged-bootstrap and Bernoulli × NB2 tests remain the implementation
checks recorded in the infrastructure report.

## Consistency Audit

The closeout search covered `staged eta`, `staged-eta`, `full-refit`,
`parametric bootstrap`, and `margin uncertainty` across the design handoff,
plan, campaign README, check log, after-task reports, `README.md`,
`ROADMAP.md`, `NEWS.md`, and known limitations. The affected developer records
now consistently say stopped or future-only. No public README, roadmap, NEWS,
formula grammar, vignette, or pkgdown change was needed because none claimed a
staged-eta interval route.

## GitHub Issue Maintenance

No issue was opened, closed, or commented on. This is an internal
developer-only lane; no public capability or bug status changed.

## What Did Not Go Smoothly

The campaign was over-scaled before observed runtime was available. The first
Totoro launcher and Fir recovery submission also had operational faults. Those
faults changed neither the estimator nor the source snapshot, but they made an
uncalibrated duration estimate unreliable. The right response was to stop
rather than spend additional compute to salvage an uncommitted feature.

## Team Learning

For a developer-only uncertainty proposal, establish product need and a
costed pilot gate before authorizing a full coverage grid. A large campaign is
appropriate only after the intended public inference claim is explicit.

## Known Limitations

Partial ledgers are preserved but non-evidential: 284 Totoro and 513 Fir
outer-result CSV shards existed at stop time. They must not be aggregated,
interpreted, or used to promote staged eta. The public staged-eta boundary is
unchanged: no SE, Wald, profile, `confint()`, interval, recovery, or coverage.

## Next Actions

Leave staged eta as point-estimation/diagnostic only. Reopen uncertainty only
after a new product-level decision asks for a public interface; then first
compare a valid two-stage variance method with a narrowly costed full-refit
bootstrap feasibility pilot before any coverage campaign.
