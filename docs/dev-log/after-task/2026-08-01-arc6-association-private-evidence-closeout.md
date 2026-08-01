# After-task: Arc 6 association private-evidence closeout

## 1. Goal

Close the Arc 6 Association private-evidence lane on current `main` without
merging or rebasing the stale F3/F4R branch.

## 2. Implemented

This closeout records the current-main provenance audit. No package code,
public API, capability-ledger entry, pkgdown page, or compute artifact was
changed.

## 3a. Decisions and Rejected Alternatives

The stale `codex/arc6-f4r-completion-review` branch is retained as historical
provenance, but is not merged: it is materially behind current `main`. The
runtime repair commits `324a00233`, `b7f0ee442`, and `38532e2ad` are already
ancestors of current `main`.

The lower-information F4 failure is retained through
`docs/dev-log/2026-08-01-arc6-f4-historical-failure-receipt.md`, which names
its immutable historical Git source and all-attempt failure denominator. The
F4R result is retained only as a private, high-information alpha-scale
interval-feasibility result for its frozen Bernoulli x ordinary-NB2,
fixed-effect, complete-pair, intercept-only grid. F5 public `vcov()` or
`confint()` exposure remains rejected pending a separate, evidence-aligned
product and validation decision.

## 4. Files Touched

- `docs/dev-log/after-task/2026-08-01-arc6-association-private-evidence-closeout.md`
- `docs/dev-log/2026-08-01-arc6-f4-historical-failure-receipt.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- Confirmed the three runtime repair commits are ancestors of `origin/main`.
- Confirmed that later point-estimate and prediction changes make
  `R/associate-pairs.R` differ from the stale F4R review branch, while public
  association uncertainty remains unchanged and fail-closed.
- Read the current-main F4R review and its 12-section after-task report. They
  retain the 16-cell, 16,000-attempt F4R screen, its 22
  `boundary_unresolved` attempts, and the explicit F4/F4R distinction.
- Confirmed current public `vcov.drm_pair_association()` and
  `confint.drm_pair_association()` remain informative fail-closed errors.
- Focused `associate-pairs-(bernoulli-nb2|staged-sandwich|arc6-integration)`
  tests and the F3-runner contract filter completed with no failures; the
  latter reports 47 passing expectations.

## 6. Tests of the Tests

The focused `associate-pairs-(bernoulli-nb2|staged-sandwich|arc6-integration)`
filter and `arc6-f3-provenance-smoke-runner` filter completed without failures;
the latter reports 47 passing expectations. They exercise current production
association behavior and the frozen-runner contract respectively; neither is
treated as fresh F3/F4R compute evidence.

## 7a. Issue Ledger

An open-issue search for `Arc 6 Association` returned no matching issue. No
issue was opened, closed, or commented on because this is a provenance
closeout, not a new public capability.

## 8. Consistency Audit

The closeout uses `alpha`, not `eta` or generic `rho12`, and names F4R as
private interval feasibility rather than public inference. It preserves the
existing fail-closed S3 behavior.

## 9. What Did Not Go Smoothly

The historical F3/F4R branch initially appeared to need integration. Direct
ancestry and file comparisons showed that the meaningful runtime repairs and
F4R review had already reached current `main`; wholesale integration would
instead reintroduce stale files and conflicts.

## 10. Known Residuals

F5 remains unapproved. No evidence here establishes an observable eligibility
rule for a public association uncertainty API, a sample-size threshold, eta
inference, slopes, other pairs, random effects, missingness, weights, offsets,
REML, profiles, or bootstrap fallback.

## 11. Team Learning

Before integrating an evidence branch, verify both commit ancestry and the
current public surface. A completed private campaign can be reconciled without
merging its stale developer runners or re-running its frozen compute.

## 12. Next Actions and Cross-Product Coverage

This closeout covers only fixed-effect Bernoulli x ordinary-NB2 association
evidence. It does not alter Gaussian `biv_gaussian()` `rho12`, any other
mixed-family pair, or the scale/interval lane.

The only possible continuation is a separately approved F5 product-and-
validation decision with a prospectively validated observable eligibility
rule; it is not authorized by this record.
