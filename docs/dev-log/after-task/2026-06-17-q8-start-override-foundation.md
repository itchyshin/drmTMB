# After Task: Q8 Start Override Foundation

## Goal

Re-bank the private start-override foundation on current `origin/main` so a
future q4-to-q8 staged-start mapper can copy selected internal TMB starts
without exposing a public start API or bypassing maps.

## Implemented

`drmTMB()` now calls private `drm_apply_start_override()` after the model spec,
estimator, penalty, and clamp data are assembled, and before `TMB::MakeADFun()`.
Ordinary fits remain unchanged because the hook is a no-op unless an internal
builder sets `spec$start_override`.

## Mathematical Contract

This task changes starting values only. It does not change a likelihood,
parameterization, symbolic model, fitted degrees of freedom, or inference label.
Mapped slots in `spec$map`, including fully mapped components such as
`factor(NA)`, keep their original start values.

## Files Changed

- `R/drmTMB.R`: added private start-override validation, name alignment,
  map-preserving application, and an applied-override record.
- `tests/testthat/test-optimizer-contract.R`: added source tests for the no-op
  path, named reordering, partially mapped starts, fully mapped starts, and
  malformed override errors.
- `docs/design/35-optimizer-start-map-multistart.md`: documented the private
  hook and kept public start/warm-start controls reserved.

## Checks Run

```sh
air format R/drmTMB.R tests/testthat/test-optimizer-contract.R
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "biv-gaussian", reporter = "summary")'
Rscript --vanilla -e 'devtools::document()'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --vanilla -e 'devtools::check(error_on = "never")'
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' R/drmTMB.R tests/testthat/test-optimizer-contract.R docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task
forbidden-framing scan over touched prose and code
```

Results:

- `optimizer-contract` passed.
- Broad `biv-gaussian` test filter passed, including q8 endpoint and q8
  endpoint recovery test files.
- `devtools::document()` completed; generated Rd/RoxygenNote drift unrelated to
  this task was removed from the PR.
- `pkgdown::check_pkgdown()` failed before this slice's scope on
  `drm_phylo_penalty` missing from `_pkgdown.yml`; that topic belongs to the
  Claude penalty/Ayumi lane and was not changed here.
- `devtools::check(error_on = "never")` passed with 0 errors, 0 warnings, and
  0 notes in 10m 57.4s on local macOS.
- `git diff --check`, conflict-marker scan, and forbidden-framing scan over
  touched prose and code passed.

## Tests Of The Tests

The first no-op test exposed an R partial-matching trap: `out$start_override`
could partially match `start_override_applied` after the hook removed the absent
override. The implementation now reads the override with exact list indexing,
and the test also uses exact indexing. The malformed-input test covers unknown
components, duplicate names, length mismatch, non-finite values, matrix values,
and mismatched named vectors.

## Consistency Audit

The design doc now separates the private hook from the future public
`start`/`start_from`/warm-start contract. No examples, vignettes, formula
grammar, README status, NEWS entry, pkgdown navigation, likelihood design, or
known-limitations row needed a behavioural update because no user-facing syntax
or fitted model support changed.

## GitHub Issue Maintenance

Inspected `drmTMB#5`, which already records older local-only q8 staged-start
work. Current `origin/main` did not contain the private start-override hook, so
this task re-banks only that foundation. The issue should be updated when the
PR opens and again if it merges.

## What Did Not Go Smoothly

`devtools::document()` produced unrelated generated documentation churn. The
noise was removed manually so the PR stays scoped. `pkgdown::check_pkgdown()`
also exposed an unrelated missing `drm_phylo_penalty` reference topic; this PR
does not fix it because that is in Claude's penalty/Ayumi lane.

## Team Learning

Rose: exact list indexing is safer than `$` in internal spec helpers because
partial matching can blur absent fields with diagnostic fields. Ada: this is a
good separable foundation PR; the q8 mapper and prepared-spec fit tail should be
separate so failures can be traced.

## Known Limitations

No public start API was added. No q4-to-q8 mapper was added. No prepared-spec
fit tail was added. No q8 convergence, power, coverage, profile, bootstrap, or
release-support claim is made. The hook only provides validated private plumbing
for future staged-start diagnostics.

## Next Actions

Open a focused PR for this foundation. Then, in a later PR, add the q4-to-q8
mapper and paired cold-vs-staged diagnostics before rerunning any larger q8
simulation or power lane.
