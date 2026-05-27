# After Task: Two-Team Phase 18 Pilot, Slices 1409-1418

## Goal

Exercise the new parallel-lane protocol with two independent teams while
preserving a serial integration gate.

## Implemented

- Team A added `docs/design/122-tweedie-scale-preflight.md`.
- Team B added focused hardening tests to
  `tests/testthat/test-phase18-truncated-nbinom2-mu-random-intercept.R`.
- Ada integrated both lanes on one branch after the parallel work completed.
- ROADMAP, the Phase 18 simulation programme, this after-task report, and the
  check-log were synchronized.

## Mathematical Contract

No fitted likelihood changed. The Tweedie note records a future fixed-effect
proposal with public `sigma = sqrt(phi)`, `1 < nu < 2`, and intercept-only
`nu ~ 1` as the first implementation gate. The zero-truncated NB2 test hardening
keeps the existing fitted surface limited to ordinary `mu` random intercepts.

## Files Changed

- `docs/design/122-tweedie-scale-preflight.md`
- `tests/testthat/test-phase18-truncated-nbinom2-mu-random-intercept.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-two-team-phase-18-pilot-slices-1409-1418.md`

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = '^phase18-truncated-nbinom2-mu-random-intercept$', reporter = 'summary')"
Rscript --vanilla -e "files <- c('docs/design/122-tweedie-scale-preflight.md','docs/design/41-phase-18-simulation-programme.md','ROADMAP.md','docs/dev-log/check-log.md','docs/dev-log/after-task/2026-05-27-two-team-phase-18-pilot-slices-1409-1418.md'); invisible(lapply(files, function(path) { readLines(path, warn = FALSE); TRUE })); cat('ok read two-team docs\n')"
rg -n "Tweedie Scale-Mapping Preflight|two-team|1409-1418|factor.*missing|malformed-neighbour|malformed-neighbor" docs/design/122-tweedie-scale-preflight.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-27-two-team-phase-18-pilot-slices-1409-1418.md tests/testthat/test-phase18-truncated-nbinom2-mu-random-intercept.R
rg -n "Tweedie|tweedie\\(" README.md ROADMAP.md NEWS.md docs/dev-log docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/27-tweedie-family-plan.md vignettes _pkgdown.yml
rg -n "truncated_nbinom2|zero-truncated NB2|random slope|sigma random|mvbind" README.md ROADMAP.md NEWS.md docs/dev-log docs/design/01-formula-grammar.md vignettes _pkgdown.yml
gh issue list --state open --search "Tweedie" --limit 20
gh issue list --state open --search "truncated_nbinom2" --limit 20
git diff --check
```

## Tests Of The Tests

The new count test checks a fitted zero-truncated NB2 model with factor
predictors and rows removed by missing predictors before enforcing positive
integer support. It also checks that neighbouring requests for random slopes,
labelled covariance, hurdle random effects, `sigma` random effects, and
bivariate `mvbind()` count models still fail.

## Consistency Audit

The Tweedie note explicitly says it is not fitted support. The status searches
kept Tweedie as planned or future-only in the README, roadmap, NEWS, formula
grammar, family registry, likelihood note, design gate, vignettes, and pkgdown
navigation. The count tests do not change implementation or admit any
neighbouring count surface. Shared global status edits were made only during
integration, not by the parallel teams.

## GitHub Issue Maintenance

`gh issue list --state open --search "Tweedie" --limit 20` found the existing
open Tweedie tracking issue, #2. No duplicate issue was opened and no issue
comment was added because this pilot only records a pre-implementation scale
preflight. `gh issue list --state open --search "truncated_nbinom2" --limit 20`
returned no open issue, so the zero-truncated NB2 hardening remains recorded in
the check-log and this after-task note.

## What Did Not Go Smoothly

The first Team A result naturally wanted to state the Tweedie scale mapping as a
decision. Ada softened the heading and text so it is clear this is a
pre-implementation design commitment, not current fitted support.

## Team Learning

The two-team protocol worked best when one team owned a docs-only future lane
and the other owned a test-only existing-surface lane. That split avoided merge
conflicts and kept package claims honest.

## Known Limitations

This pilot did not implement Tweedie and did not run broad package checks. The
Tweedie family still needs likelihood implementation, comparator tests,
simulation tests, documentation, and provenance review before support is
claimed.

## Next Actions

- If the owner accepts the Tweedie scale mapping, open a narrow Tweedie
  fixed-effect implementation lane.
- Keep zero-truncated NB2 random slopes, `sigma` random effects, hurdle random
  effects, structured count effects, and bivariate count models closed until
  separate evidence exists.
