# Phase 18 Shared Runner Migration Audit

Reader: `drmTMB` contributors checking the status of Slices 556-578 after the
NB2 phylogenetic q1 formal audit.

This note records the overnight revalidation pass for the requested Slices
556-578 list. Older Phase 18 ledgers already used some of these slice numbers
for May 19 work, so this note is not a renumbering of the historical ledger.
It is a current-state audit of the same shared-runner contracts in this dirty
branch. The pass did not add a new likelihood, formula grammar, or user-facing
model surface. Its purpose was to confirm that the shared bounded
replicate-runner path already exists in the current branch and that the first
set of migrated simulation surfaces still pass their focused tests.

## Slice Map

| Slices | Purpose | Current status |
| --- | --- | --- |
| 556-558 | Freeze the Slices 541-555 audit state and re-check the shared runner API | Confirmed from `inst/sim/R/sim_runner.R` and `tests/testthat/test-phase18-sim-runner.R` |
| 559-560 | Check serial and Unix `multicore` worker caps plus requested versus actual worker metadata | Focused runner tests pass; the public artifact column remains `cores` for actual workers |
| 561-562 | Gaussian location-scale migration and validation | Focused migrated-runner test passes |
| 563-564 | `meta_V(V = V)` migration and validation | Focused migrated-runner test passes |
| 565-566 | Poisson `mu` random-effect migration and validation | Focused migrated-runner test passes |
| 567-568 | NB2 `mu` random-effect migration and validation | Focused migrated-runner test passes |
| 569-570 | NB2 `sigma` random-intercept migration and validation | Focused migrated-runner test passes |
| 571-572 | NB2 phylogenetic q1 migration and comparator-row validation | Focused migrated-runner test passes |
| 573-578 | Manifest, warning-ledger, interval-status, README, design, and after-task evidence | This note and the after-task report record the current evidence; broader validation moves to Slices 579-605 |

## Checked Contract

The shared runner contract remains:

- `backend = "none"` runs serially with `cores = 1`.
- `backend = "multicore"` is Unix-only and caps actual workers at 10, the
  requested core count, and the number of replicate tasks.
- Each replicate keeps its cell id, replicate number, seed, fit status,
  warnings, elapsed time, summary rows, and parallel metadata.
- `summarise_fun_factory` may create a per-replicate summariser when profile or
  bootstrap settings need replicate-specific state.
- Nested replicate-layer and bootstrap-layer multicore plans are rejected before
  fitting.

The first migrated surfaces remain ordinary Phase 18 simulation evidence lanes.
They do not promote NB2 phylogenetic q1 beyond `hold_smoke_only`, do not open
NB2 `sigma` phylogeny, and do not add new non-Gaussian structured-dependence
syntax.

## Validation

The Slices 556-578 audit used:

```sh
Rscript -e "devtools::test(filter = 'phase18-sim-runner', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18-(gaussian-ls-runner|meta-v-runner|poisson-mu-random-effect|nbinom2-mu-random-effect|nbinom2-sigma-random-effect|nbinom2-phylo-q1)', reporter = 'summary')"
```

Both commands passed on May 24, 2026. The next slice block should validate
artifact schemas and broader Phase 18 surfaces rather than reworking the shared
runner API.
