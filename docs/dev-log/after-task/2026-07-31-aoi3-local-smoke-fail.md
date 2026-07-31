# After Task: AOI-3 local full-refit smoke — fail-closed

## 1. Goal

Run the owner-authorized AOI-3 local smoke for the private Bernoulli x
ordinary-NB2 multi-column staged sandwich. The gate required five formula
classes at `n = 720`, one outer DGP each, and seven complete inner refits per
eligible outer fit before any DRAC uncertainty-calibration submission.

## 2. Implemented

The private runner and executable calibration contract were frozen at source
SHA `e9a24c30350ca3b5c5fc783ae161840ded905a23`. It generated five retained
outer attempts and 35 scheduled inner rows under
`docs/dev-log/simulation-artifacts/2026-07-31-aoi3-local-smoke/`.

The strict reducer returned `AOI3_LOCAL_SMOKE_FAIL_DRAC_BLOCKED`. The `mixed`,
`numeric_interaction`, and `transformation` outer fits were interior with an
available private sandwich. `factor_interaction` was interior but its private
sandwich was unavailable because of `association_step_unstable`; its seven
inner rows are therefore correctly `not_eligible`. The `additive` outer fit
was `boundary_unresolved`, so its seven scheduled inner rows are also
`not_eligible`. Of the eligible 21 inner refits, 19 were interior and two
transformation refits were `boundary_unresolved`.

## 3a. Decisions and Rejected Alternatives

The local smoke fails its predeclared all-formula gate. Therefore no DRAC
campaign was staged or submitted. The rejected alternatives are to omit the
additive outer failure, replace it with another seed, count `not_eligible`
inner rows as successes, weaken the seven-inner requirement after observing
the result, or treat the four successful outer fits as uncertainty validation.

## 4. Files Touched

- `docs/dev-log/2026-07-31-aoi3-full-refit-calibration-contract.md`
- `tools/run-aoi3-bernoulli-nb2-full-refit.R`
- `tools/summarize-aoi3-bernoulli-nb2-smoke.R`
- `tests/testthat/test-aoi3-full-refit-runner.R`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3-local-smoke/`
- this receipt

## 5. Checks Run

- The runner parsed and its focused contract test passed.
- A one-outer/one-inner complete-refit runner check passed before freezing the
  smoke source SHA.
- The five-worker local smoke completed with empty worker stderr logs.
- The initial reducer exposed a formula-specific CSV-schema defect; it was
  repaired by unioning columns, then the retained immutable outputs were
  reduced without rerunning the smoke.
- The repaired reducer retained all five outer and 35 inner rows and wrote the
  explicit `AOI3_LOCAL_SMOKE_FAIL_DRAC_BLOCKED` decision.

## 6. Tests of the Tests

The reducer requires exactly five formula outputs, one common 40-character
source SHA, five interior outer fits with `sandwich_status == "ok"`, and 35
interior/available inner results. Formula-specific coefficient schemas are now
unioned rather than silently dropped or requiring identical columns. Thus the
additive unavailable outer and transformation unavailable inners mechanically
force the recorded fail decision.

## 7a. Issue Ledger

No issue, capability-ledger cell, public API, public article, or uncertainty
surface changed. AOI-2's `HOLD_NO_POINT_RECOVERY_CLAIM` is unchanged. AOI-3
does not have calibration evidence and remains unavailable.

## 8. Consistency Audit

This result follows the AOI-3 contract's all-attempt rule and its distinction
between an outer DGP failure, an ineligible inner resample, and an unavailable
inner refit. It does not touch Lane B `sd()`/profile work, Arc D, the foreign
Association PR #854, or `R/associate-pairs.R`.

## 9. What Did Not Go Smoothly

The first reducer assumed identical coefficient columns across formulae and
failed before writing an analysis result. This was an analysis-program defect,
not a smoke failure; the raw outputs were already complete and unchanged. The
repair preserves the union of formula-specific columns and the raw evidence.
The full-refit workload also showed the interaction formula to be materially
slower than the completed simpler formulae, which is retained as planning
information only.

## 10. Known Residuals

The smoke is not a calibration study and provides no coverage, covariance,
standard-error, or interval estimate. It identifies a failure of this fixed
smoke route, not a universal cause or an estimator repair. No alternative
AOI-3 design has been selected.

## 11. Team Learning

Formula-flexible association evidence must preserve a union schema at analysis
time; an assumption of common coefficient columns would selectively erase
exactly the multi-parameter cases AOI was designed to test. The private
sandwich availability gate is independently load-bearing: an interior
association point fit does not license an inner uncertainty calculation. More
importantly, complete full refits make a small smoke expensive enough that the
fail-closed gate is a necessary protection against an unjustified large
campaign.

## 12. Cross-Product Coverage

This review covers only the local mechanical AOI-3 smoke for frozen-margin
Bernoulli x ordinary-NB2, fixed-effect, complete-pair association formulae.
It does NOT cover AOI-2 point recovery, full uncertainty calibration,
coefficient covariance validity, SEs, intervals, coverage, random/structured
association effects, missingness, weights, offsets, REML, other family pairs,
`vcov()`, `confint()`, profiles, or public capability claims.

## Next Actions

Keep DRAC blocked under this contract. A later owner decision may define a new,
separately frozen AOI-3 route that explains and addresses the additive outer
boundary outcome and transformation inner instability; it must begin with a
new local smoke and must not pool with this failed one.
