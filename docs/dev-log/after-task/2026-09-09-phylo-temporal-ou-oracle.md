# After Task: Phylogenetic-temporal OU dense covariance oracle

## 1. Goal

Independently verify the additive stable-phylogeny plus within-species OU
covariance before treating the admitted paired formula as a validated model.

## 2. Implemented

A new test helper simulates an unbalanced 12-species fixture from `ape::vcv()`
and independent OU paths. Its dense Gaussian likelihood constructs
\(s_b^2 A + I(i=j)s_a^2\exp[-\lambda|t-s|] + \sigma^2I\) directly. The
suite verifies native objective, score, and observed Hessian; the runner now
fails closed when any oracle expectation fails and exposes G3–G6.

## 3a. Decisions and Rejected Alternatives

The reference uses `ape::vcv(tree, corr = TRUE)`, direct dense matrices, and
base Gaussian linear algebra; it does not reuse drmTMB's phylogenetic precision
or temporal covariance construction. The separable phylogeny-by-OU field is a
negative control, not an implemented alternative.

## 4. Files Touched

- `tests/testthat/helper-phylo-temporal-ou-reference.R`
- `tests/testthat/test-phylo-temporal-ou-dense-oracle.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- `tools/phylo-temporal-ou-gates.R`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md`
- `docs/dev-log/after-task/2026-09-09-phylo-temporal-ou-oracle.md`
- `docs/dev-log/plan-actual/2026-09-09-phylo-temporal-ou-oracle.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G3`, `G4`, `G5`, and `G6`
returned their expected PASS markers. The focused dense-oracle suite passed 19
assertions. The focused gate-runner suite passed 6 assertions. `git diff --check`
passed.

## 6. Tests of the Tests

The new test first failed because it tried to recover the tree through an absent
formula environment; the repaired oracle receives the independent tree
explicitly. It then caught a name-preserving permutation that accidentally
realigned itself. The final misaligned-tree mutation changes labels without
reordering covariance values and is detected. The test suite rejects the
missing phylogenetic off-diagonal, separable field, shared OU state, omitted
stable component, omitted OU normalization, and tree misalignment.

## 7a. Issue Ledger

Open issue #1302 remains the tracker for this feature. No issue comment or
external message was sent because this is local verification work.

## 8. Consistency Audit

The reference equations match the P1 plan's additive model and explicitly name
the cross-species nonzero-lag entry as stable phylogenetic covariance only.
No public documentation changed: deterministic oracle evidence does not yet
qualify public prediction, inference, simulation, recovery, or calibration.

## 9. What Did Not Go Smoothly

The first independent oracle tried to obtain a tree from a fitted call, which
has no retained formula environment. Passing the test fixture's tree explicitly
removed that hidden dependency. Two matrix-mutation controls were also tightened
so names cannot silently repair a wrong permutation.

## 10. Known Residuals

This evidence covers one generated fixture and deterministic finite differences.
It does not establish conditional modes, public methods, profile behavior,
recovery, interval coverage, performance, or robustness across data designs.

## 11. Team Learning

For an additive covariance model, a cross-species entry at nonzero time lag is
the most useful discriminating check: the stable phylogenetic term remains,
whereas the independent OU term vanishes. A correctly labelled permutation is
not a misalignment test because name indexing repairs it.

## 12. Cross-Product Coverage

This oracle covers Gaussian ML, `sigma ~ 1`, the one phylogenetic intercept,
the one same-ID OU term, irregular times, unbalanced series, and shuffled rows.
It does NOT cover REML, ordinary intercepts, AR1 plus phylogeny, slopes,
labels, non-Gaussian families, missing predictors, known covariance, multiple
structured layers, simulation/extraction methods, profile endpoints, interval
coverage, performance, package checks, rendered docs, Julia parity, or a
campaign. Those cells remain governed by later P1 gates.
