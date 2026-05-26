# After Task: Phase 18 First-Wave Summary Runner Revalidation Slices 899-908

## Goal

Revalidate the reusable private first-wave summary smoke runner and its
requested-versus-actual worker summary.

## Implemented

Added `docs/design/108-phase-18-first-wave-summary-runner-revalidation-slices-899-908.md`
to record current source and focused-test evidence. This is a revalidation note
because `docs/dev-log/after-task/2026-05-20-slices-899-908-phase18-first-wave-smoke-runner.md`
already recorded the original runner slice. No likelihood, formula grammar,
public API, roxygen topic, pkgdown navigation, package site output, or formal
statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is private simulation-runner plumbing:
the runner stages first-wave summary artifacts and records requested versus
actual worker counts. The current runner has expanded since the original
three-surface slice; that is recorded as current state, not as a new claim here.

## Files Changed

- `docs/design/108-phase-18-first-wave-summary-runner-revalidation-slices-899-908.md`
- `docs/dev-log/after-task/2026-05-25-phase18-first-wave-summary-runner-revalidation-slices-899-908.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
sed -n '1,130p' docs/dev-log/after-task/2026-05-20-slices-899-908-phase18-first-wave-smoke-runner.md
sed -n '685,698p' docs/design/41-phase-18-simulation-programme.md
nl -ba inst/sim/run/sim_run_first_wave_summary_smoke.R | sed -n '1,220p'
nl -ba inst/sim/run/sim_run_first_wave_summary_smoke.R | sed -n '197,270p'
nl -ba tests/testthat/test-phase18-first-wave-summary-smoke-runner.R | sed -n '55,125p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner)', reporter = 'summary')"
```

Results:

- Source reads confirmed the original May 20 after-task note introduced the
  runner for the then-current three-surface bundle.
- Source reads confirmed current `phase18_run_first_wave_summary_smoke()` now
  stages Gaussian location-scale, `meta_V(V = V)`, count random-effect,
  Gaussian random-slope, and spatial slope outputs.
- Source reads confirmed current `phase18_first_wave_parallel_summary()` and
  `phase18_parallel_summary_row()` record `backend`, `requested_cores`, and
  actual `cores`.
- The focused first-wave summary-report, render-helper, and summary-smoke-runner
  tests completed with exit code 0.
- The current runner test expects seven parallel-summary rows, requested cores
  of 10, actual cores of 1 under `backend = "none"`, report-status/table
  artifacts, 43 aggregate rows, 19 Wald coverage rows, nonzero profile coverage
  rows, and malformed-input errors.
- No files were staged or committed.

## Tests Of The Tests

The focused runner test exercises a real temporary output directory and checks
both successful output staging and malformed input paths. It also checks the
worker-summary columns indirectly through the returned `parallel_summary`.

## Consistency Audit

This is current-state revalidation, not a new runner expansion. The current
source has seven surface entries because later slices expanded the runner after
Slices 899-908. This note does not change supported model surfaces or make
final simulation claims.

## GitHub Issue Maintenance

Reused the open-issue search from the preceding first-wave summary slice.
Umbrella issue #59 covers Phase 18 reporting; no issue mutation was done from
this mixed dirty branch.

## What Did Not Go Smoothly

The runner no longer matches the original three-surface description exactly
because later first-wave slices have expanded it. The revalidation note records
that drift instead of silently rewriting history.

## Team Learning

Rose should explicitly mark current-state revalidation when source code has
evolved beyond an older slice note. Grace should keep requested-versus-actual
worker summaries in tests because they are easy to lose while expanding smoke
runners.

## Known Limitations

This slice did not run a rendered `n_rep = 2` smoke. It only revalidated current
runner source and focused tests.

## Next Actions

Continue with Slices 909-918 by validating the rendered `n_rep = 2` smoke from
the reusable runner, if that evidence is still present and current.
