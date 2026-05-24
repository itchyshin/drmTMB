# After-Task Report: Poisson Phylogenetic q1 Evidence Sync, Slices 436-450

## Purpose

Synchronize the source and evidence ledgers after adding the Poisson
phylogenetic q1 runner contract. This keeps fitted support, runner readiness,
and broad Phase 18 simulation admission separate.

## Scope Completed

- Updated `vignettes/source-map.Rmd` so the Poisson mean row points to the
  Poisson q1 ADEMP sheet and runner contract.
- Updated `docs/design/34-validation-debt-register.md` so the
  `poisson_phylo_q1_mu` row and broader structured non-Gaussian row name the
  runner contract as the next gate.
- Updated `docs/design/41-phase-18-simulation-programme.md` so count and
  phylogenetic scenario lanes keep Poisson q1 phylogeny separate from ordinary
  count random-effect and Gaussian phylogenetic grids.
- Updated `docs/design/46-pre-simulation-readiness-matrix.md` so the Poisson q1
  and structured non-Gaussian rows point to both Poisson q1 design documents.
- Updated `docs/design/02-family-registry.md` so the Poisson evidence state
  points to the runner contract before recovery-runner claims.
- Updated ROADMAP and NEWS for slices 436-450.

## Review Perspectives

Ada checked ledger consistency. Jason checked the source-map route. Fisher and
Curie checked simulation-readiness wording. Boole checked that the Poisson q1
syntax stayed narrow. Pat checked user-facing status boundaries. Grace checked
validation commands. Rose checked that evidence-ledger sync did not become a
new fitted-support claim. These were role perspectives, not spawned agents.

## Remaining Boundary

The ledgers now agree that ordinary Poisson q1 phylogenetic `mu` is fitted but
still needs runner-contract implementation and recovery evidence before broad
operating-characteristic claims. NB2, zero-inflated, hurdle, spatial, animal,
`relmat()`, slope, q2/q4, scale, shape, ordinal, bounded-response, and
mixed-response structured routes remain planned or blocked.

## Validation

Run before commit:

```sh
air format NEWS.md ROADMAP.md vignettes/source-map.Rmd docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-poisson-phylo-q1-evidence-sync-slices-436-450.md
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
rg -n 'poisson.*phylo.*(formal operating-characteristic evidence|broad Phase 18 operating-characteristic evidence|admitted for broad|ready for broad|formal recovery claim|formal coverage claim)' README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
git diff --check
```

Results:

- `air format` completed without output.
- `pkgdown::check_pkgdown()` reported no problems.
- The narrowed false-support scan returned no hits.
- The tighter Poisson phylogeny broad-claim scan returned no hits. A broader
  exploratory scan found only intended boundary sentences such as "not broad"
  and "before any broad grid."
- `git diff --check` was clean.
