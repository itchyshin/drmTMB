# After Task: Q8 Staged-Fit Diagnostic Runner

## Goal

Add the small private runner needed to compare a q > 2 target fit from its
ordinary cold starts against the same target fit after applying the private
q > 2 staged-start override.

## Implemented

`drm_qgt2_staged_fit_diagnostic()` now:

- builds staged-start provenance with `drm_qgt2_staged_start_override()`;
- fits the target specification cold with `drm_fit_spec()`;
- fits the same target specification again after setting `spec$start_override`;
- captures warnings and errors for each attempt;
- records convergence, `pdHess` when available, objective, log-likelihood,
  elapsed seconds, optimizer preset, warning count/text, and error text;
- returns a cold-versus-staged delta table for objective, log-likelihood, and
  elapsed seconds.

The implemented claim is narrow: internal diagnostic code can now compare cold
and staged q > 2 target fits through the ordinary fit tail.

## Mathematical Contract

This task does not change a likelihood, formula grammar, estimator, parameter
mapping, or numerical guard. The diagnostic runner delegates both attempts to
`drm_fit_spec()`, which preserves the selected-optimum invariant:

```text
All reported quantities must be functions of the selected optimum opt$par.
```

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-optimizer-contract.R`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-q8-staged-fit-diagnostic-runner.md`

## Checks Run

```sh
air format R/drmTMB.R tests/testthat/test-optimizer-contract.R
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
Rscript --vanilla -e 'devtools::document()'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --vanilla -e 'devtools::check(error_on = "never")'
Rscript --vanilla -e 'devtools::test(reporter = "summary")'
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' R/drmTMB.R tests/testthat/test-optimizer-contract.R docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-17-q8-staged-fit-diagnostic-runner.md
git diff -U0 | rg '^\+.*(non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML-on-scale|REML.*scale)'
```

Focused optimizer-contract tests passed. The combined optimizer-contract plus
q8 endpoint/recovery Phase 18 subset passed. `devtools::document()` completed;
unrelated generated Rd/RoxygenNote drift was removed from the PR.
`pkgdown::check_pkgdown()` failed on the pre-existing `drm_phylo_penalty` topic
missing from `_pkgdown.yml`, which belongs to the Claude penalty/Ayumi lane and
was not changed here. `devtools::check(error_on = "never")` passed with 0
errors, 0 warnings, and 1 environment note: future-file timestamp checking
could not verify the current time. Full `devtools::test()` passed with exit 0;
it reported five existing Julia/cross-family skips and eight expected
log-sigma clamp warnings from the pathological clamp test. Static diff,
conflict-marker, and added-line forbidden-framing scans passed.

## Tests Of The Tests

The new optimizer-contract test exercises the success path through an injected
fake fit tail. It verifies that the cold path has no applied start override,
the staged path does apply overrides, the staged-start provenance is retained,
the comparison table contains cold and staged metrics, and the objective delta
is calculated from the two attempts. The same test also checks the failure path
where `fit_spec` is not a function.

## Consistency Audit

No user-facing syntax changed. Public `start`, `start_from`, `warm_start`, and
`map` controls remain reserved and unavailable. The runner is private
infrastructure for the next q8 smoke artifact; it is not evidence that q8
convergence, positive-Hessian recovery, interval calibration, power, speed, or
release readiness are solved.

Task-specific scans used during the slice:

```sh
rg -n "staged-fit|staged fit|cold-versus-staged|q8|warm-start|start_from|non-identified|flat/unbounded|REML on scale|REML-on-scale" docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md README.md ROADMAP.md NEWS.md docs vignettes R tests
git diff -U0 | rg '^\+.*(non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML-on-scale|REML.*scale)'
```

The broad scan is noisy because historical after-task notes preserve wording
that was true when written. The added-line scan returned no matches.

## GitHub Issue Maintenance

Issue `drmTMB#5` owns the q8 endpoint follow-up path. Comment there when the
PR opens and when it merges. No new issue is needed for this internal runner.

## What Did Not Go Smoothly

The runner could have been placed in the Phase 18 artifact layer, but it needs
direct access to the private mapper and prepared-spec fit tail. Keeping it in
`R/drmTMB.R` avoids a second fitting path and lets Phase 18 artifacts call one
tested internal helper later.

## Team Learning

Curie's testing constraint mattered: the unit test verifies the diagnostic
bookkeeping without adding a slow full q8 numerical fit to every CRAN-safe test
run. Fisher's boundary matters too: a lower staged objective in a diagnostic
run is not yet recovery evidence until a deliberately sized simulation grid
shows how often and where it helps.

## Known Limitations

No Phase 18 artifact calls this runner yet. No real cold-versus-staged q8
simulation grid has been run. No status row should promote q8 recovery, power,
intervals, speed, or release readiness from this slice.

## Next Actions

Open the focused PR and comment on `drmTMB#5`. A later artifact slice can wire
this helper into an opt-in q8 cold-versus-staged smoke task and report
diagnostic outcomes without changing public user syntax.
