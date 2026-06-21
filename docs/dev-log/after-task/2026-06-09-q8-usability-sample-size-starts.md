# After Task: Q8 Usability, Sample Size, And Start Strategies

## Goal

Make the q8 all-endpoint bivariate Gaussian route more useful without
overpromoting it: add a validated theta staged-start option, test whether q8
QA is sample-size dependent, and leave profile/bootstrap artifacts that record
what works and what remains diagnostic.

## Implemented

- Added optional q4-to-q8 `theta_re_cov` staged starts through
  `drm_qgt2_staged_start_override(copy_theta_re_cov = TRUE)`. The mapper uses
  pair labels, shrinks copied correlations, regularizes the target correlation
  matrix if needed, packs the matrix back to TMB's unstructured-correlation
  theta scale, and verifies reconstruction.
- Added `phase18_biv_gaussian_q8_usability_conditions()` with the five hard
  stress rows plus a 24 x 6, 48 x 10, and 96 x 12 sample-size ladder.
- Added `phase18_run_biv_gaussian_q8_usability_pilot()` and
  `phase18_run_biv_gaussian_q8_inference_pilot()` to compare cold,
  q4 SD-staged, and q4 theta-staged starts, then write direct-SD profile and
  derived-correlation bootstrap evidence.
- Wrote artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-pilot/` and
  `docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-inference-pilot/`.

## Mathematical Contract

The q8 endpoint model has eight group-level endpoint SDs and 28 group-level
endpoint correlations for the labelled `(1 + x | p | id)` block across
`mu1`, `mu2`, `sigma1`, and `sigma2`. Residual `rho12` remains the residual
coscale parameter and is not one of the q8 group-level correlations.

The theta mapper never copies packed q4 theta positions into q8 by position. It
maps source pair labels to target pair labels, fills unmatched q8 pairs with
zero, shrinks matched correlations, and uses
`correlation_matrix_to_tmb_unstructured_theta()` so the TMB start reconstructs
the intended q8 correlation matrix.

## Evidence

The 2026-06-09 fit pilot supports a sample-size conditional interpretation.
At low sample size, cold and SD-staged starts errored with a non-positive
leading minor, while theta-staged got through but still returned optimizer code
1. At baseline sample size, all three starts fit but q8 correlation matrices
were near singular. At 96 groups x 12 repeats, cold and SD-staged `se = TRUE`
fits reported `pdHess = TRUE`, with minimum q8 correlation eigenvalues
2.05e-6 and 4.26e-6 and condition numbers 1.27e6 and 6.11e5. Those high-row
fits still returned optimizer code 1 under the 800-iteration budget.

Theta-staged starts helped selected hard rows but are not a blanket rescue. On
the weak-SD stress row, theta-staged reached optimizer code 0 with minimum q8
correlation eigenvalue 2.83e-7 and condition number 1.20e7 after the cold fit
errored. On the high sample-size row, theta-staged `se = TRUE` reported
`pdHess = FALSE` where cold and SD-staged reported `pdHess = TRUE`.

The inference pilot confirmed the boundary. A direct endpoint-SD profile on the
weak-SD row returned a 70% interval of 0.135 to 0.194, with one
`NA/NaN function evaluation` warning and 71 seconds elapsed. The requested
30-second elapsed limit was best-effort because native TMB/profile code did not
yield immediately. The two-refit derived-correlation bootstrap wrote 29 draw
rows, but one refit was nonconverged and one errored, so it wrote no interval
rows.

## Files Changed

- `R/drmTMB.R`
- `inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R`
- `tests/testthat/test-optimizer-contract.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/163-phase-18-q8-hessian-start-rescue.md`
- `docs/design/165-phase-18-q8-start-hook-preflight.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/team-improvements.md`
- `inst/sim/README.md`

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla - <<'RS'
# styler::style_file(c(
#   "inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R",
#   "tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R"
# ))
RS
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
```

Result: `styler` changed the q8 runner and q8 test file; focused tests passed
after styling.

```sh
/usr/local/bin/Rscript --vanilla - <<'RS'
# Wrote docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-pilot/
phase18_run_biv_gaussian_q8_usability_pilot(...)
RS
```

Result: wrote `fit-summary.csv`, `profile-targets.csv`, `start-mapping.csv`,
`failures.csv`, and `manifest.csv`.

```sh
/usr/local/bin/Rscript --vanilla - <<'RS'
# Wrote docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-inference-pilot/
phase18_run_biv_gaussian_q8_inference_pilot(...)
RS
```

Result: wrote `inference-source-fit.csv`, `direct-sd-profile.csv`,
`derived-correlation-bootstrap-draws.csv`,
`derived-correlation-bootstrap-intervals.csv`, and `manifest.csv`.

## Tests Of The Tests

The optimizer-contract tests now check the q4-to-q8 theta-start path by
reconstructing the target q8 correlation matrix from the packed theta vector.
They assert that matched source pair correlations are copied with shrinkage and
that unmatched q8 pairs remain neutral. The q8 Phase 18 tests check the
sample-size ladder, explicit bootstrap failure accounting, mixed-schema mapping
row binding, and CSV manifest helper behaviour.

## Consistency Audit

Synchronized the q8 status wording in README, ROADMAP, the readiness matrix,
the capability worklist, q8 design notes, the simulation README, and the known
limitations ledger. The wording now treats q8 as sample-size and conditioning
dependent, not as a binary works/does-not-work result.

Stale scans used:

```sh
rg -n "q8|Q8|theta_re_cov|staged|sample-size|sample size|bootstrap|profile" docs/design/163-phase-18-q8-hessian-start-rescue.md docs/design/165-phase-18-q8-start-hook-preflight.md docs/design/157-capability-completion-worklist.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/known-limitations.md inst/sim/README.md ROADMAP.md NEWS.md docs/dev-log/team-improvements.md README.md
rg -n "theta_re_cov.*refus|does not copy packed|without a validated pair-key|q8.*does not work|q8.*would not work|q8.*works" README.md NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md inst/sim tests R --glob "!docs/dev-log/after-task/**" --glob "!docs/dev-log/recovery-checkpoints/**" --glob "!docs/dev-log/simulation-artifacts/**"
git diff --check -- R/drmTMB.R inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R tests/testthat/test-optimizer-contract.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R README.md NEWS.md ROADMAP.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/67-sdstar-p8-poisson-q1.md docs/design/157-capability-completion-worklist.md docs/design/163-phase-18-q8-hessian-start-rescue.md docs/design/165-phase-18-q8-start-hook-preflight.md docs/dev-log/check-log.md docs/dev-log/known-limitations.md docs/dev-log/team-improvements.md inst/sim/README.md docs/dev-log/after-task/2026-06-09-q8-usability-sample-size-starts.md
```

Result: the stale-copying and binary-q8 scan returned no rows, and
`git diff --check` was clean.

## GitHub Issue Maintenance

Issue #5 is the overlapping q8 all-endpoint issue. The GitHub connector could
read the issue, but posting the closeout comment failed with GitHub API 403
`Resource not accessible by integration`. The local after-task report and
check-log therefore carry the issue update text until a maintainer or a
write-enabled token can post it.

## What Did Not Go Smoothly

The first high-sample inference attempt was too slow and did not return useful
artifacts. The bounded inference runner now records profile/bootstrap attempts,
but `setTimeLimit()` is not a hard wall around native TMB/profile work, so
profile elapsed time can still exceed the requested limit.

## Team Learning

Q8 QA should be reported as sample-size conditional. The right question is not
"does q8 work?" but "at this replication, optimizer budget, Hessian status, and
correlation conditioning, which q8 quantities are fit, profile-ready, or still
derived-unavailable?"

## Known Limitations

Q8 remains fitted and diagnostic-artifact ready, not coverage-ready or
power-ready. Direct endpoint-SD profiles are feasible on selected rows but can
be slow. Derived q8 group-level correlations remain unavailable for public
profile/bootstrap intervals, and the first developer bootstrap pilot produced
no interval rows.

## Next Actions

Run a deliberately sized q8 pilot at larger replication with a larger optimizer
budget. Compare cold and SD-staged starts as the primary candidates, keep
theta-staged starts as a row-specific diagnostic option, and only then decide
whether q8 should enter any coverage or power grid.
