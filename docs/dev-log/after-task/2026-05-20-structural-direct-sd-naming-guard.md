# After Task: Structural Direct-SD Naming Guard

## Goal

Close the small public-interface gap noticed after PR #267: the first
animal/`relmat()` slice is merged, but the reference page still makes
`sd_phylo*()` highly visible. The task was to keep the existing implemented
phylogenetic direct-SD syntax honest while preventing the team from copying the
same family-specific naming pattern into spatial, animal, and `relmat()` routes.

## Implemented

- Kept `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` documented as the current
  implemented phylogenetic direct-SD interface.
- Added explicit wording that these names are not a template for future
  `sd_spatial*()`, `sd_animal*()`, or `sd_relmat*()` names.
- Repaired stale status text in `ROADMAP.md`,
  `docs/design/37-worked-example-inventory.md`, and
  `docs/dev-log/forgotten-promises-status-2026-05-20.md` now that
  `animal(A/Ainv)` and `relmat(K/Q)` have a fitted first slice.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'no fitted animal|no fitted relmat|no fitted.*animal|no fitted.*relmat|design boundary only; no fitted|planned marker examples|no fitted `animal|no fitted `relmat' README.md ROADMAP.md docs vignettes R man
rg -n 'sd_spatial\*\(\)|sd_animal\*\(\)|sd_relmat\*\(\)|not a naming pattern|not a template|generic direct-SD naming' R/random-effect-scale-formulas.R docs/design/01-formula-grammar.md docs/design/23-large-data-memory.md ROADMAP.md docs/dev-log/forgotten-promises-status-2026-05-20.md man/random_effect_scale_formulas.Rd
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems, and `git diff --check` was
clean. The stale-wording scan still finds historical after-task, figure-audit,
check-log, and recovery-checkpoint entries that were true when written; Ada did
not rewrite those archival records.

## Issue Maintenance

Issue #147 remains the main animal/`relmat()` parity ledger. This slice does
not close it and does not add a new issue because it is a documentation guard
for the next parity work, not a new model capability.

## Team Learning

- Ada: small public-interface corrections should happen before adding more
  parity slices.
- Boole: one generic direct-SD grammar is easier to learn than separate
  family-specific helper names for every structured layer.
- Rose: stale status rows can survive a green PR and must be scanned again
  after merge.

These were role perspectives, not spawned agents.

## Next Actions

1. Open the spatial "toward phylo parity" lane from this cleaner naming base.
2. Add a small runnable animal/`relmat()` known-matrix example before claiming
   examples are complete.
