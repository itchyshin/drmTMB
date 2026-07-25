# After Task: Arc 7 B0 `meta_V` B3 retained-evidence integration

## 1. Goal

Make the existing negative small-K Gaussian ML `meta_V()` heterogeneity-interval
evidence reproducible on current main, without new compute, a capability claim,
or an interval-validity/coverage claim.

## 2. Implemented

Arc 7 B0 retains the actual public `confint(..., method = "wald")` result for
`sigma`, classifies `[0, Inf]` as `degenerate_zero_infinite`, and preserves an
all-attempt denominator. It now also retains a compact, provenance-bearing B3
campaign reduction and the historical campaign report. The reader documentation
states that convergence and `pdHess` are necessary fit diagnostics, not proof
that a `sigma` interval is finite, usable, or calibrated.

## 3. Mathematical Contract

The only model covered is Gaussian ML
`bf(yi ~ x + meta_V(V = V), sigma ~ 1)`. Known `V` is input data and `sigma` is
residual heterogeneity. The primary B3 result is the rate of finite,
truth-covering Wald intervals over all scheduled attempts; conditional
finite-interval set coverage is secondary and cannot replace it.

## 3a. Decisions and Rejected Alternatives

B0 selectively retains the evidence contract and compact campaign reduction.
It rejects a wholesale merge of the stale B3 branch, a repeat or extension of
the campaign, and any capability or calibration claim. Profile/bootstrap work
is deferred to a separately approved research arc.

## 4. Files Touched

- `inst/sim/dgp/sim_dgp_meta_v.R`, `inst/sim/fit/sim_summarise_meta_v.R`, and
  `inst/sim/run/sim_*meta_v*` carry the B3 contract and all-attempt accounting.
- `docs/design/48-phase-18-meta-v-ademp.md` and the B3 packet/plan record the
  bounded estimand and exclusions.
- `docs/dev-log/evidence/2026-07-23-meta-v-b3-retained-reduction.md` and
  `docs/dev-log/after-task/2026-07-23-meta-v-b3-campaign.md` retain compact
  provenance from the historical campaign without its raw or remote artifacts.
- `vignettes/meta-analysis.Rmd` and `inst/sim/README.md` now fence the
  interval interpretation precisely.

## 5. Checks Run

- Direct K=12 vector boundary, `sigma=0.10`, sampling SD=0.12, seed 4:
  estimate `2.389998e-06`; Wald `[0, Inf]`; status
  `degenerate_zero_infinite`; convergence and `pdHess` both `TRUE`.
- Direct K=36 dense control, `sigma=0.35`, sampling SD=0.12, `rho=0.25`, seed
  4: estimate `0.2556934`; Wald `[0.1914417, 0.3415092]`; status `ok`.
- The two-cell harness manifest retained the K=12 interval as degenerate and
  non-finite, while the dense control was finite and usable.
- Focused `testthat::test_file()` runs passed for `phase18-meta-v-dgp`,
  `phase18-meta-v-grid-writer`, `phase18-meta-v-summary-smoke`, and
  `comparators`.
- `git diff --check` passed before the closeout documentation edits.

## 6. Tests of the Tests

The deterministic K=12 seed-4 regression test asserts the exact public
zero-infinite interval. The all-attempt summary test injects both an error and
a degenerate interval, proving that neither vanishes from the primary
denominator. Comparator tests cover the ML point-estimate/likelihood convention
against `metafor`; they do not claim interval calibration.

## 8. Consistency Audit

Searched `README.md`, `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`,
`docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`,
`_pkgdown.yml`, the meta-analysis vignette, and the ADEMP for
`meta_V|meta_known_V|meta_gaussian|tau ~|interval.*coverage|coverage.*interval|capability.*tier`.
The active reader surfaces retain the route as implemented/tested but
tier-unregistered, without an interval or coverage claim.

## 7a. Issue Ledger

No issue changed. Draft PR #828 is the scoped review surface; it remains open
and draft, with no automatic merge. The retained campaign's historical Phase 18
umbrella issue was #59.

## 9. What Did Not Go Smoothly

The first direct sentinel omitted local simulation utility sourcing, and an
initial read used the installed rather than working-tree simulation scripts.
The final sentinel loaded the working tree explicitly. Fisher and Rose also
identified two reader statements that could overstate what `pdHess` and a
generic coverage label establish; both were repaired before closeout.

## 11. Team Learning

An evidence-integration lane must retain a compact provenance-bearing reduction,
not only repeat campaign numbers in a plan or handover. A successful optimizer
and Hessian do not rescue a degenerate boundary interval.

## 10. Known Residuals

B0 does not establish interval validity, coverage, inference readiness, a
capability tier, public performance, REML, `sigma ~ x`, profile/bootstrap
intervals, proportional or misspecified `V`, non-Gaussian meta-analysis,
clustered effects, arbitrary dense covariance, Julia support, or CRAN status.
It did not run Totoro or DRAC.

## 12. Cross-Product Coverage

This evidence lane changes neither the public R API nor formula grammar,
likelihood, Rd files, pkgdown navigation, Julia bridge, or CRAN state. It does NOT cover REML, penalties, alternative interval engines, missing-data or
aggregation routes, other estimands, vector/dense covariance beyond the exact
14-cell B3 grid, or non-Gaussian and bivariate model families.

## Next Actions

Keep PR #828 draft for review. The next large arc, if approved, should be a
separate pre-registered heterogeneity-interval-method research program with a
new estimand/procedure decision, smoke gate, and remote-compute authorization.
