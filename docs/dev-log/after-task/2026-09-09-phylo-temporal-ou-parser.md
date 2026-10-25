# After Task: Phylogenetic-temporal OU parser and layout

## 1. Goal

Admit exactly the approved Gaussian ML formula containing a stable
phylogenetic intercept and an independent same-species OU process, while
rejecting nearby unsupported combinations before they reach the likelihood.

## 2. Implemented

The Gaussian builder now admits only `phylo(1 | species, tree = tree)` paired
with `temporal(1 | species, time = elapsed, structure = "ou")`. The resulting
temporal layout records `paired_phylo_stable = TRUE` and requires three distinct
positive lags. It validates raw IDs, elapsed time, duplicate species-time keys,
tree/species matching, at least three species, and at least two raw times per
species before response omission. It then rechecks three retained species and
two retained observations per species after omission.

## 3a. Decisions and Rejected Alternatives

The admitted pair has the same grouping ID and no ordinary random intercept.
AR1 plus `phylo()`, slopes, labels, extra structured terms, and trees with a
different tip set remain refused. This is an additive stable-phylogeny plus
independent-OU layout; it does not implement the future separable
phylogeny-by-OU field.

## 4. Files Touched

- `R/temporal.R`
- `R/drmTMB.R`
- `tools/phylo-temporal-ou-gates.R`
- `tools/temporal-source-map-gates.R`
- `tests/testthat/test-phylo-temporal-ou-parser.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md`
- `docs/dev-log/after-task/2026-09-09-phylo-temporal-ou-parser.md`
- `docs/dev-log/plan-actual/2026-09-09-phylo-temporal-ou-parser.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G2` returned
`PHYLO_TEMPORAL_OU_G2_PASS`. Focused test files
`test-phylo-temporal-ou-parser.R`, `test-temporal-parser.R`,
`test-temporal-ou.R`, and `test-phylo-temporal-ou-gate-runner.R` passed with
12, 6, 64, and 6 assertions respectively. `M03` returned
`TEMPORAL_SOURCE_MAP_M03_PASS`; `git diff --check` passed.

## 6. Tests of the Tests

The new paired-form test was first run against the old structured-effect guard
and failed as expected. It now fits an intentionally shuffled data set and
asserts the named paired layout. Failure tests cover grouping mismatch, an
ordinary intercept, fewer than three species, raw duplicate key hidden behind a
missing response, a singleton retained species after response omission, and a
tree tip mismatch. The G2 worker independently fits the admitted public call
and tries a mismatched-ID call that must fail.

## 7a. Issue Ledger

Open issue #1302 already tracks `Feature: phylogenetically correlated temporal
OU series`. No issue was opened or commented on because this parser slice is
local implementation work and no external message was authorized.

## 8. Consistency Audit

The formula spelling is exactly the approved plan spelling. Existing standalone
temporal AR1 and OU parsing and OU behavior passed their focused regressions.
No public README, NEWS, formula grammar, likelihood document, vignette, or
pkgdown page was updated: the full implementation claim remains blocked on the
independent dense oracle and later public-method gates.

## 9. What Did Not Go Smoothly

The original Phase-0 fingerprint revalidator required the current Git `HEAD` to
equal the immutable source pin, which made later legitimate source work look
stale. It now validates the recorded pin format, current native-source hash,
and R/TMB environment, preserving the baseline evidence without pretending the
worktree never advances.

## 10. Known Residuals

A single public fit shows that the existing provider can hold both latent
components, but it is not native-likelihood validation. The dense marginal
covariance, score, Hessian, conditional modes, mutation suite, extraction,
profile boundary, recovery, and calibration campaign are unreviewed in this
slice.

## 11. Team Learning

A paired covariance model needs validation twice: raw metadata must be checked
before response omission, and retained-series support must be checked after it.
The latter prevents a superficially valid raw data set from producing an
unidentified one-observation temporal path.

## 12. Cross-Product Coverage

This parser/layout slice covers Gaussian ML, `sigma ~ 1`, no weights beyond one,
one unlabelled phylogenetic intercept, one same-ID OU term, shuffled input rows,
and response omission guards. It does NOT cover REML, an ordinary intercept,
AR1 plus phylogeny, phylogenetic or temporal slopes, labels, non-Gaussian
families, missing predictors, known covariance, multiple structured layers,
newdata, the separable field, intervals, profiles, simulation, package checks,
rendered docs, Julia parity, or campaigns. The P1 later gates own those cells.
