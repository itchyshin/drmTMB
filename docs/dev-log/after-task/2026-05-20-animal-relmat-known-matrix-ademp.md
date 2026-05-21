# After Task: Animal/Relmat Known-Matrix ADEMP Gate

## Task Goal

Create the Phase 18 design gate for fitted known-matrix `animal()` and
`relmat()` Gaussian `mu` intercepts plus matching bivariate q=2 `mu1`/`mu2`
location covariance. The goal was not to add a simulation runner yet. It was
to make the next simulation step honest: state the hierarchy, estimands,
methods, performance measures, MCSE expectations, and failure-ledger rows
before any broad grid is run.

## Files Created Or Changed

- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-20-animal-relmat-known-matrix-ademp.md`

## Checks Run

Checks run:

```sh
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n 'still needs its own ADEMP sheet|until the bivariate q=2 .*ADEMP|Ready only for known-matrix Gaussian `mu` intercept smoke cells' docs/design README.md ROADMAP.md NEWS.md vignettes
```

Outcomes:

- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.
- The stale-wording scan found no remaining current claims that the q=2
  animal/`relmat()` lanes still lack an ADEMP sheet.

## Consistency Audit

The design sheet separates five layers that are easy to conflate:
known matrix input, structured SD, structured q=2 group-level correlation,
residual scale, and residual `rho12`. The Phase 18 programme and readiness
matrix now say that the q=2 animal/`relmat()` lanes have an ADEMP design gate,
but broad grids still need DGP, runner, and summariser code.

## Tests Of The Tests

No executable tests were added in this slice. The next executable test should
be a small deterministic DGP/runner smoke test that proves the generated truth
rows and fitted estimand rows line up before a formal grid is attempted.

## What Did Not Go Smoothly

This slice was stacked while GitHub Actions was still checking the runnable
examples PR. That kept progress moving, but it means the branch should be
rebased or fast-forwarded after the examples PR lands so the final diff only
contains the ADEMP work. The first stale-wording scan also used double quotes
around a pattern containing backticks, so the shell tried to execute `mu`; the
scan was rerun with single quotes and completed cleanly.

## Team Learning And Process Improvements

Curie and Fisher should keep using ADEMP sheets as the simulation admission
gate. Pat and Darwin should stay involved before code is written, because the
simulation design is only useful to users if it names what a fitted model can
actually support and what remains a planned feature. Rose should keep scanning
for readiness rows that accidentally turn "has a design sheet" into "has
finished simulation evidence".

## Design-Doc Updates

The new design sheet records the `animal()`/`relmat()` known-matrix DGP,
condition factors, estimands, intended formulae, and performance measures. The
Phase 18 programme and pre-simulation readiness matrix now point to that sheet
and state the remaining implementation gate.

## Pkgdown And Documentation Updates

No new pkgdown article or reference page was added. The existing
structural-dependence article from the preceding runnable-examples slice is the
reader-facing motivation for the future simulation report.

## GitHub Issue Maintenance

This slice is part of the open structural-dependence parity ledger tracked in
issue #147. No issue comment should be added until the branch is pushed or a PR
is opened.

## Known Limitations And Next Actions

The next slice should add a small `inst/sim/` DGP helper and runner smoke for
the known-matrix animal/`relmat()` q=2 lane. Pedigree-to-`Ainv` construction,
structured slopes, `sigma` structured effects, q=4 location-scale blocks,
predictor-dependent `corpair()` regressions, direct-SD grammar, and
non-Gaussian structured effects remain failure-ledger rows.
