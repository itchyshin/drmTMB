# Slices 669-678: Phase 18 Runner Status Audit

## Goal

Ada reconciled the roadmap and simulation-programme notes with the bounded
Phase 18 runner work completed in Slices 539-668.

## Implemented

The repository now states that private Phase 18 bootstrap and replicate-runner
execution support is implemented locally for the existing smoke surfaces, while
broad operating-characteristic grids, public bootstrap intervals, and PSOCK
execution remain outside the implemented package surface.

## Mathematical Contract

No likelihood, formula grammar, or estimand definition changed. The audit
documents execution mechanics only: serial versus Unix `multicore`, worker
caps, runner metadata, and closure-aware per-replicate summarisation for
profile or bootstrap seed handling.

## Files Changed

- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-20-slices-669-678-phase18-runner-status-audit.md`

## Checks Run

```sh
git diff --check
```

Result:

- No whitespace errors.

## Tests Of The Tests

This slice did not add tests. It follows the clean validation baseline from
Slices 639-668: focused Phase 18 tests, full package tests, pkgdown checks, and
package checks all passed after the runner migration.

## Consistency Audit

Ada and Rose checked the current wording around Phase 18 runner, bootstrap,
core-cap, PSOCK, planned animal, planned `relmat()`, and planned skewness
surfaces. The new text deliberately separates private simulation helpers from
future public confidence-interval APIs.

## What Did Not Go Smoothly

The slice numbering now has a large jump because the Ayumi hard-case and
package-audit work happened between the initial Phase 18 blueprint and the
latest runner migration. The design note records that bridge explicitly so the
next agent does not assume Slices 539-668 were public simulation grids.

## Team Learning

- Ada: keep the roadmap staged rather than binary planned/done when
  infrastructure is implemented but broad grids are still ahead.
- Curie: private runner metadata is part of the simulation evidence, not just
  convenience plumbing.
- Fisher: bootstrap rows are diagnostic interval evidence until formal
  operating-characteristic grids prove their behaviour.
- Grace: PSOCK should stay out of the package claim until fitted-object rebuild
  semantics are explicit.
- Rose: status bridges prevent old roadmap language from making implemented
  work look missing or, worse, making private infrastructure look public.

## Known Limitations

- No public `confint(method = "bootstrap")` route was implemented.
- No PSOCK backend was added to the package helper.
- No animal, `relmat()`, skew-normal, or broad Phase 18 grid support was added.

## Next Actions

1. Write a recovery checkpoint after the audit.
2. Continue with the next narrow Phase 18 surface or package-doc audit rather
   than opening a broad grid before the first-wave reports are staged.
