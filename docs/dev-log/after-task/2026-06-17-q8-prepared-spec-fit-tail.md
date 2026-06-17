# After Task: Q8 Prepared-Spec Fit Tail

## Goal

Add the private fit-tail helper needed before a future q4-to-q8
cold-versus-staged diagnostic runner can fit a built target specification with
an internal start override.

## Implemented

`drmTMB()` now delegates its post-builder fit path to private
`drm_fit_spec()`. The helper takes a built specification plus the original
formula, family, parsed control, REML flag, parsed penalty, and call. It applies
the same estimator, phylogenetic-penalty, log-sigma clamp, start-override,
TMB-construction, optimizer, selected-optimum, uncertainty, missing-data,
parameter-splitting, and storage-control steps as the ordinary public fit path.

The implemented claim is narrow: an internal built `spec` can be fitted through
the same tail as `drmTMB()` without duplicating the optimizer and reporting
code.

## Mathematical Contract

This task does not change a likelihood, formula grammar, distributional
parameter, or estimator. It preserves the selected-optimum invariant:

```text
All reported quantities must be functions of the selected optimum opt$par.
```

The helper still calls `drm_pin_tmb_object_to_optimum()` after optimization and
splits fitted parameters from `obj$env$parList(opt$par)`.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-optimizer-contract.R`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-q8-prepared-spec-fit-tail.md`

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
rg -n '^(<<<<<<<|=======|>>>>>>>)' R/drmTMB.R tests/testthat/test-optimizer-contract.R docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-17-q8-prepared-spec-fit-tail.md
git diff -U0 | rg '^\+.*(non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML-on-scale|REML.*scale)'
```

Focused optimizer-contract tests passed. The combined optimizer-contract plus
q8 endpoint/recovery Phase 18 subset passed. `devtools::document()` completed;
unrelated generated Rd/RoxygenNote drift was removed from the PR.
`pkgdown::check_pkgdown()` failed on the pre-existing `drm_phylo_penalty` topic
missing from `_pkgdown.yml`, which belongs to the Claude penalty/Ayumi lane and
was not changed here. `devtools::check(error_on = "never")` passed with 0
errors, 0 warnings, and 0 notes in 11m 11s. Full `devtools::test()` passed with
exit 0; it reported five existing Julia/cross-family skips and eight expected
log-sigma clamp warnings from the pathological clamp test. Static diff,
conflict-marker, and added-line forbidden-framing scans passed.

## Tests Of The Tests

The new optimizer-contract test would fail before this change because
`drm_fit_spec()` did not exist. It builds a Gaussian location-scale spec
directly, fits it with `drm_fit_spec()`, and compares the resulting fitted
object against the ordinary `drmTMB()` path: call, formula, family, starts,
start-override record, coefficients, random-effect summaries, missing-data
metadata, log-likelihood, degrees of freedom, observation count, estimator,
penalty fields, optimizer provenance, and uncertainty status.

## Consistency Audit

No user-facing syntax changed. Public `start`, `start_from`, `warm_start`, and
`map` controls remain reserved and unavailable. No examples, vignettes,
pkgdown navigation, README status rows, or NEWS entries should promote this
internal helper as a user feature.

Task-specific scans used during the slice:

```sh
rg -n "prepared-spec|prepared spec|fit tail|q8|staged-start|warm-start|start_from|non-identified|flat/unbounded|REML on scale|REML-on-scale" docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md README.md ROADMAP.md NEWS.md docs vignettes R tests
git diff -U0 | rg '^\+.*(non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML-on-scale|REML.*scale)'
```

The broad scan is noisy because historical after-task notes preserve wording
that was true when written. The touched prose uses the current boundary:
private helper and q8 plumbing only, no public warm-start or q8 evidence claim.
The added-line scan returned no matches.

## GitHub Issue Maintenance

Issue `drmTMB#5` owns the q8 endpoint follow-up path. The issue should receive
a PR comment when this branch is opened and a close-out comment when it merges.
No new issue is needed for this internal helper.

## What Did Not Go Smoothly

The main risk was copying an older local `drm_fit_spec()` idea that predated
the current estimator, penalty, log-sigma clamp, optimizer retry, and selected
state handling. This slice avoided that by extracting the current public fit
tail instead of reviving stale helper code.

## Team Learning

Emmy's architecture point is the durable one: future diagnostic runners should
reuse the ordinary fit tail rather than grow a second optimizer path. Rose's
audit point is equally important: this is enabling infrastructure, not q8
simulation evidence.

## Known Limitations

No paired cold-versus-staged q8 diagnostic run exists yet. The staged-start
mapper and fit-tail helper have source tests, but they do not establish q8
convergence rescue, positive-Hessian recovery, interval calibration, power,
speed, or release readiness.

## Next Actions

Open a focused PR and comment on `drmTMB#5`. After this helper merges, the next
q8 slice can add a small diagnostic runner that fits the same q8 target cold
and with a staged start, records convergence, `pdHess`, objective, elapsed
time, warnings, and start-provenance metadata, and still treats the result as
diagnostic until a deliberately sized simulation grid is accepted.
