# After Task: Arc 8 dense known-`V` direct-SD interval feasibility

## 1. Goal

Build a local-only, source-pinned feasibility gate for the two dense Gaussian
known-`V` LSS direct-SD coefficients, without beginning recovery, coverage, a
capability promotion, or any Totoro/DRAC work.

## 2. Implemented

Added a separate Arc 8 four-cell dense ladder, with the Arc 7B K = 12
historical failure control pinned to its original seed. The runner now records
full `TMB::tmbprofile` intervals, target-wise bootstrap completion, all
bootstrap refit diagnostics, and a fail-closed combined gate for
`sd(study):(Intercept)` and `sd(study):z_study`.

## 3a. Decisions and Rejected Alternatives

Arc 8 keeps both direct-SD coefficients as a single gate. It rejects an
intercept-only interpretation, any new estimator or profile engine, and a
remote campaign based only on the manually successful engineering fixtures.

## 3b. Mathematical Contract

The estimator remains Gaussian ML
`bf(yi ~ x + (1 | study) + meta_V(V = V), sigma ~ z, sd(study) ~ z_study)`.
For each direct-SD coefficient, a complete profile requires status `profile`,
finite ordered endpoints, and containment of its fitted estimate. A complete
Arc 8 cell requires those conditions and at least 95% finite successful
bootstrap refits for *both* coefficients. This is feasibility engineering, not
interval calibration or coverage evidence.

## 4. Files Touched

The Arc 8 plan and manual local receipt are in `docs/dev-log/`; the runner is
`inst/sim/run/sim_run_meta_v_lss_smoke.R`; focused contract tests are in
`tests/testthat/test-phase18-meta-v-lss-runner.R`. The runner's returned
`bootstrap_diagnostics` table retains one row for every target/refit attempt,
including outer seed, target availability, refit status, and whether the draw
was used.

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter =
  "phase18-meta-v-lss-runner", reporter = "stop")'`: passed.
- A direct `phase18_run_meta_v_lss_arc8()` K = 12 engineering smoke with
  `bootstrap_R = 2`: returned two target rows, four retained target-refit
  diagnostic rows, an Arc 8 surface label, and a two-target gate.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused runner tests retain the original source seed, test completion-rate
failure handling, check that the returned diagnostics retain every two-target
refit, assert the Arc 8 surface label, and prove the combined gate fails if
either target lacks bootstrap completion or its fitted estimate lies outside
the recorded profile interval.

## 7a. Issue Ledger

No issue or pull request was changed. This local HOLD neither resolves an
existing tracker nor supports a public capability claim.

## 8. Consistency Audit

Arc 8 remains separate from eta and bivariate work. It does not change the
likelihood, formula grammar, public `meta_V()` API, Gaussian oracle, DH route,
reader-facing documentation, capability ledger, or PR #828. The Arc 7B
failure control is structural input to the new runner rather than a result
filtered out of its denominator.

## 9. What Did Not Go Smoothly

The initial Arc 8 receipt used manual local fixtures from an earlier source
SHA. Review correctly identified that this was not a reproducible run of the
committed runner, and that aggregate bootstrap counts were insufficient for an
all-attempt audit. The runner was therefore tightened before this report.

## 10. Known Residuals

The finite K = 12/36/72 engineering ladder and the K = 36 199-refit sidecar
predate the committed runner integration. The exact historical K = 12 control
is now source-pinned and unit-tested but has not yet produced a fresh Arc 8
all-attempt artifact. There is no recovery, calibration, coverage, remote
compute, tier, or reader-facing claim.

## 11. Team Learning

Fisher's 2026-07-24 task review records a local-feasibility-only verdict: one
successful engineering fixture does not provide recovery, bias, MCSE, or
coverage evidence. Rose required the combined two-target predicate, explicit
estimate containment, source-distinct all-attempt rows, and retained
refit-level bootstrap diagnostics. Both reviews withhold a compute request
until the source-pinned control is rerun.

## 12. Cross-Product Coverage

Arc 8 covers only the univariate Gaussian ML dense known-`V` LSS runner and
its two `sd(study)` fixed-effect coefficients. It **does NOT cover** eta,
bivariate models, DH, REML, alternative profile engines, missing data, PR #828,
or reader-facing `meta_V()` documentation.

## Next Actions

**HOLD — do not submit DRAC work.** From a clean committed SHA, run the Arc 8
source-pinned historical control with a persistent result directory and retain
its manifest, command/session receipt, all target-profile states, and every
bootstrap-refit row. That negative control must reproduce its retained
incomplete/non-finite state; it is not required to pass the interior-feasibility
predicate. Separately, a predeclared interior cell must pass the two-target
profile-containment plus bootstrap-completion gate. Only then may Fisher and
Rose be asked whether a *separate* recovery/coverage compute proposal is
warranted.
