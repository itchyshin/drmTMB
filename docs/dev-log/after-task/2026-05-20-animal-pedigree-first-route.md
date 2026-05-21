# After Task: Animal Pedigree First Route

## Goal

Fit the first useful `animal(pedigree = ...)` surface for applied users who
have dam/sire pedigrees, while keeping sparse large-pedigree speed, slopes,
`sigma`, q=4, and predictor-dependent `corpair()` claims out of the fitted
surface.

## Implemented

`animal(1 | id, pedigree = pedigree)` now accepts a pedigree data frame with
`id`, `dam`, and `sire` columns. Unknown parents can be `NA`, `""`, or `"0"`.
The implementation orders ancestors before descendants, builds a dense
additive relationship matrix, and sends that matrix through the existing
known-relatedness precision path. Matching labelled bivariate terms such as
`animal(1 | p | id, pedigree = pedigree)` now use the same route for the
first q=2 Gaussian location covariance.

## Mathematical Contract

For a pedigree-derived animal effect, the fitted location model uses
\(\mathbf{g} \sim \mathrm{MVN}(0, \sigma^2_{\mathrm{animal}}\mathbf{A})\),
where \(\mathbf{A}\) is the additive relationship matrix generated from
`id`, `dam`, and `sire`. The recursion sets founder diagonal entries to 1,
offspring-parent relatedness to one half of the known-parent relationship, and
the offspring diagonal to \(1 + 0.5 A_{\mathrm{dam},\mathrm{sire}}\) when both
parents are known. This is a dense first route, not the final sparse
large-pedigree `Ainv` construction.

## Files Changed

- `R/drmTMB.R`
- `R/phylo-utils.R`
- `R/formula-markers.R`
- `man/animal.Rd`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `tests/testthat/_snaps/animal-relmat-gaussian.md`
- `tests/testthat/test-gaussian-location-scale.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/44-structured-slope-parity-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`
- `docs/design/55-phase-18-animal-relmat-q2-interval-status.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian')"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian|package-skeleton')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale|animal-relmat-gaussian|package-skeleton')"
git diff --check
rg -n 'pedigree-to-Ainv|pedigree construction|Direct pedigree|direct `pedigree|pedigree-derived precision|pedigree-derived animal models|When animal-model support becomes fitted|animal\(1 \| id, pedigree = ped\).*Planned|animal\(1 \| individual, pedigree = pedigree\).*Planned' README.md NEWS.md ROADMAP.md R docs/design vignettes tests man
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(error_on = 'never')"
```

Outcomes:

- `animal-relmat-gaussian` passed 60 expectations.
- The combined `animal-relmat-gaussian|package-skeleton` run passed 152
  expectations.
- The broader focused run
  `gaussian-location-scale|animal-relmat-gaussian|package-skeleton` passed 232
  expectations after an old planned-pedigree boundary assertion was updated.
- `git diff --check` was clean.
- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::check(error_on = "never")` finished with 0 errors, 0 warnings,
  and 0 notes.
- The stale-wording scan returned historical `NEWS.md` text from the 0.1.3
  release, generated `vignettes/model-map.html`, and intended
  sparse-large-pedigree or structured-slope planned-boundary wording.

## Tests Of The Tests

The new tests compare `animal(pedigree = ...)` likelihoods to the already
fitted `animal(A = ...)` and `animal(Ainv = ...)` routes, so a wrong pedigree
matrix or alignment would break equality. Failure-path snapshots cover missing
parents, parent-offspring cycles, and the still-rejected structured-slope
request.

## Consistency Audit

Rose searched source docs, tests, and generated roxygen output for stale
planned-pedigree claims with:

```sh
rg -n 'pedigree-to-Ainv|pedigree construction|Direct pedigree|direct `pedigree|pedigree-derived precision|pedigree-derived animal models|When animal-model support becomes fitted|animal\(1 \| id, pedigree = ped\).*Planned|animal\(1 \| individual, pedigree = pedigree\).*Planned' README.md NEWS.md ROADMAP.md R docs/design vignettes tests man
```

Current source docs now say `animal(pedigree = ...)` is fitted for the first
Gaussian location surface. They still say sparse large-pedigree construction,
animal slopes, animal `sigma`, q=4 blocks, predictor-dependent `corpair()`,
and direct-SD grammar are planned.

## GitHub Issue Maintenance

Issue #147 was inspected as the active animal/`relmat()` known-relatedness
ledger. A status-comment attempt failed with GitHub API 403
(`Resource not accessible by integration`), so this local report and the
check log carry the handoff. The issue should remain open because sparse
large-pedigree construction, structured slopes, scale models, q=4 blocks, and
direct-SD naming still need their own evidence.

## What Did Not Go Smoothly

The first snapshot run failed because the old planned-pedigree error was
correctly replaced by malformed-pedigree errors, and the snapshot order needed
manual synchronization. The first full-check pass then caught an older
`test-gaussian-location-scale.R` boundary assertion that still expected
`animal(pedigree = ...)` to fail; that test now keeps only the structured-slope
rejection. The second full-check pass was clean.

## Team Learning

Ada kept the slice narrow by routing pedigree support through the existing
known-relatedness machinery. Pat and Darwin judged the change useful because
many applied users have dam/sire tables before they have `A` or `Ainv`.
Fisher and Curie required equivalence tests rather than only convergence
tests. Rose kept sparse large-pedigree claims out of the public status text.

## Known Limitations

This is a dense first route for small examples and focused tests. It does not
claim ASReml-like large-pedigree speed, sparse pedigree inverse construction,
animal structured slopes, animal `sigma`, q=4 location-scale blocks,
predictor-dependent animal `corpair()` regression, or generic direct-SD
syntax.

## Next Actions

- Add a separate sparse large-pedigree `Ainv` construction gate before making
  scalability claims.
- Keep structured animal slopes out of Phase 18 grids until slope-specific
  recovery, diagnostics, and profile targets exist.
- Extend the animal examples only where they answer concrete eco-evo
  questions, not as matrix mechanics demonstrations.
