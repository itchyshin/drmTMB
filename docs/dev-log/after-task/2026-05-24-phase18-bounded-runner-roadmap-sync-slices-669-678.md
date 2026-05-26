# After Task: Phase 18 Bounded-Runner Roadmap Sync Slices 669-678

## Goal

Synchronize roadmap and simulation-programme wording with the implemented
bounded-runner status while keeping the private Phase 18 bootstrap artifact
path separate from the limited public direct-target bootstrap interval route.

## Implemented

Updated ROADMAP and Phase 18 programme wording, then added
`docs/design/86-phase-18-bounded-runner-roadmap-sync-slices-669-678.md` to
record the sync audit.

No likelihood, formula grammar, public API, roxygen topic, pkgdown navigation,
or rendered site output changed.

## Mathematical Contract

No model changed. The checked contract is execution and evidence vocabulary:
serial and Unix `multicore` are the private Phase 18 package-helper backends,
actual workers are capped, bootstrap artifact rows are simulation evidence, and
the public `confint(..., method = "bootstrap")` route remains a selected
direct-target interval method.

## Files Changed

- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/86-phase-18-bounded-runner-roadmap-sync-slices-669-678.md`
- `docs/dev-log/after-task/2026-05-24-phase18-bounded-runner-roadmap-sync-slices-669-678.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
rg -n "bounded|parallel|multicore|PSOCK|psock|bootstrap interval|public bootstrap|bootstrap_backend|requested_cores|actual|cores|Slices 669-678|669|678|Phase 18" ROADMAP.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md
rg -n "phase18_runner_parallel_plan|psock|multicore|requested_cores|bootstrap_backend|bootstrap.backend|phase18_assert_no_nested_parallel" inst/sim/R inst/sim/run tests/testthat/test-phase18-* .github/workflows/phase18-simulation-grid.yaml
air format ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/86-phase-18-bounded-runner-roadmap-sync-slices-669-678.md docs/dev-log/after-task/2026-05-24-phase18-bounded-runner-roadmap-sync-slices-669-678.md docs/dev-log/check-log.md
git diff --check
rg -n 'broad operating-characteristic grids and public bootstrap intervals remain planned|keeping public bootstrap intervals and PSOCK support out|support.*psock|backend.*psock|PSOCK remains excluded|private Phase 18 bootstrap artifact path|limited public direct-target' ROADMAP.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/design/86-phase-18-bounded-runner-roadmap-sync-slices-669-678.md docs/dev-log/after-task/2026-05-24-phase18-bounded-runner-roadmap-sync-slices-669-678.md
Rscript -e "pkgdown::check_pkgdown()"
```

Results:

- The sync audit found one stale ROADMAP phrase about public bootstrap intervals
  remaining planned.
- ROADMAP now separates broad Phase 18 operating-characteristic grids from the
  limited public direct-target `confint(..., method = "bootstrap")` route.
- The Phase 18 programme now says that private simulation bootstrap artifacts
  are separate from public direct-target bootstrap intervals and that PSOCK
  stays outside the package simulation helpers.
- Runner code and tests continue to reject `psock` for Phase 18 package helpers
  and support only `none` or Unix `multicore`.
- The remaining ROADMAP `psock` hit is the developer-only Ayumi bootstrap
  prototype for a specific diagnostic target, not Phase 18 package-helper
  support.
- `air format` completed without output.
- `git diff --check` was clean.
- `pkgdown::check_pkgdown()` reported no problems.
- No files were staged or committed.

## Tests Of The Tests

This was a documentation sync. The evidence came from source and test scans for
backend choices, worker metadata, bootstrap metadata, PSOCK rejection, and
nested-parallel guards. The preceding Slices 656-668 focused runner bundle had
already passed in this same run.

## Consistency Audit

The report does not expand public bootstrap intervals, does not add PSOCK to
Phase 18 package helpers, and does not change unsupported non-Gaussian
sub-model random-effect boundaries.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

The first stale-wording scan used backticks inside a shell command and zsh
tried to execute `multicore`; the follow-up source scan still exposed the
wording risk, and the audit note records the corrected source-level boundary.

## Team Learning

Phase 18 has two bootstrap concepts now: private simulation artifact evidence
and the public direct-target `confint()` method. Future reports should name
which layer they mean.

## Known Limitations

`pkgdown::build_site()` was not rerun for this documentation-only sync. A later
user-facing or pkgdown-navigation change should rebuild the site.

## Next Actions

Continue with Slices 679-688 by auditing or validating the wrapper forwarding
of bounded runner settings through the first grid and count-gallery wrappers.
