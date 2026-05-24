# After-Task Report: Poisson Phylogenetic q1 Runner Contract, Slices 421-435

## Purpose

Close the next planning chunk after the non-Gaussian structured issue ledger by
turning the fitted ordinary Poisson q=1 phylogenetic `mu` route into concrete
runner, artifact, malformed-input, extractor, diagnostic, and documentation
contracts. This task did not add likelihood, TMB, parser, or formula-grammar
code.

## Scope Completed

- Added `docs/design/72-poisson-phylo-q1-runner-contract.md`.
- Recorded the required `log_sd_phylo` profile target, `sdpars$mu` row,
  `ranef("phylo_mu")` route, fixed `mu` coefficients, and absent q1
  `corpairs()` row.
- Defined required artifact-manifest and warning/error ledger columns.
- Defined local smoke-grid levels and the formal-grid admission gate.
- Added unsupported syntax guidance for Poisson slopes, q2/q4 blocks, `zi`,
  NB2, spatial, animal, `relmat()`, scale, shape, ordinal, bounded-response,
  and mixed-response neighbours.
- Added focused malformed-input, extractor-name, diagnostic-row, and
  simulation-artifact test-plan rows.
- Corrected the count tutorial so ordinary Poisson q1 phylogenetic `mu` is
  separated from the planned neighbouring count routes.
- Updated ROADMAP, NEWS, implementation-map, likelihood notes, and the Poisson
  ADEMP sheet to point to the runner contract.

## Review Perspectives

Ada kept this chunk as a planning and documentation task. Boole checked that
the route remains one family, one component, one layer, and q=1. Fisher and
Curie checked the simulation, MCSE, manifest, failure-ledger, and formal-grid
criteria. Pat checked the count tutorial boundary. Grace checked validation
commands. Rose checked for stale wording that would imply broad NB2, spatial,
animal, `relmat()`, `zi`, or hurdle count support. These were role
perspectives, not spawned agents.

## Remaining Boundary

The fitted route is still only ordinary non-zero-inflated Poisson
`phylo(1 | species, tree = tree)` in `mu` on the log-mean scale. NB2
phylogeny, zero-inflated phylogeny, hurdle phylogeny, structured count slopes,
labelled q2/q4 count covariance, spatial count structure, animal count
structure, `relmat()` count structure, and non-Gaussian structured scale or
shape effects remain planned.

## Validation

Run before commit:

```sh
air format NEWS.md ROADMAP.md docs/design/03-likelihoods.md docs/design/70-phase-18-poisson-structured-q1-ademp.md docs/design/72-poisson-phylo-q1-runner-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-poisson-phylo-q1-runner-contract-slices-421-435.md vignettes/count-nbinom2.Rmd vignettes/implementation-map.Rmd
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
rg -n 'phylo\(\), spatial\(\), animal\(\), or relmat\(\) count models|all .*phylo.*count.*planned|all `phylo\(\)` count' README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
git diff --check
```

Results:

- `air format` completed without output.
- `pkgdown::check_pkgdown()` reported no problems.
- The narrowed false-support scan returned no hits.
- The stale count-phylogeny boundary scan returned no hits after the runner
  contract wording was tightened.
- `git diff --check` was clean.
