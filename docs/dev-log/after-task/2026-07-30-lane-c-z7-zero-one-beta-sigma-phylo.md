# Lane C Z7 — zero-one-beta phylogenetic sigma q1

## 1. Goal

Implement and test only ML zero-one-beta phylogenetic sigma q1 `mc-0593`.

## 2. Implemented

The single structured-field carrier dispatches its sigma code to `log_sigma`.
R accepts only unlabelled `phylo(1 | species, tree = tree)` in sigma; its
natural-scale SD is visible but unavailable to profiling.

## 3a. Decisions and Rejected Alternatives

Only one phylogenetic intercept is in scope. Slopes, labels, q2+, ordinary or
other-dpar random effects, other providers, missingness, profiles, intervals,
bootstrap, coverage, and wider zero-one-beta claims remain excluded.

## 4. Files Touched

`R/drmTMB.R`, `R/profile.R`, `src/drmTMB.cpp`, the focused test, runner, and
retained receipts carry this work.

## 5. Checks Run

The focused zero-one-beta suite passes. The source-bound run-3 fixture passes
four of four frozen seeds; run-1/run-2 runner errors remain retained.

## 6. Tests of the Tests

The independent full mixture plus phylogenetic-Gaussian-prior oracle agrees
with TMB objective and AD gradient. Formula neighbours, dependency, extractor,
and no-refit profile fences are tested.

## 7a. Issue Ledger

`mc-0593` awaits the fresh Noether/Fisher/Rose panel and no move is claimed
here.

## 8. Consistency Audit

No Future-extension, Lane A/B, evaluated-profile, interval, coverage,
bootstrap, or remote-compute surface changed.

## 9. What Did Not Go Smoothly

Tree scope and report accessor defects occurred in the runner. Their records
remain; a corrected runner restarted all frozen seeds without statistical change.

## 10. Known Residuals

The zero-truth-SD result is diagnostic only. The internal carrier name remains
`phylo_mu`, although its explicit dpar code is sigma.

## 11. Team Learning

Fixtures must obtain TMB reports from the fitted objective, not an optional
stored report slot.

## 12. Cross-Product Coverage

This covers only complete-response univariate ML model type 15 with one
phylogenetic sigma intercept and fixed mu/zoi/coi. It does NOT cover q2+, other
dpars/providers, slopes, labels, covariance, missingness, profiles, intervals,
bootstrap, coverage, association, or bivariate/high-q routes.
