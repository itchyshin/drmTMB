# After Task: Slice 291 Pre-Simulation Evidence Ledger

## Goal

Close the pre-simulation gate by giving Rose and Fisher a concrete ledger for
checking whether public fitted claims have implementation evidence, tests or
diagnostics, user-facing boundaries, and Phase 18 simulation status.

## Implemented

`docs/design/46-pre-simulation-readiness-matrix.md` now has a Slice 291
evidence-ledger gate. The gate maps each public stable-core row to
implementation evidence, test/diagnostic/interval evidence, user-facing
boundaries, and Phase 18 admission status. It also says that planned or blocked
rows can appear only as failure-ledger rows.

`docs/design/41-phase-18-simulation-programme.md` now requires each new DGP row
to trace back to that gate before it enters an admitted simulation grid.
`docs/design/34-validation-debt-register.md` now says the validation-debt
register and Slice 291 gate must be read together for simulation admission.

## Mathematical Contract

No likelihood, formula grammar, fitted model, extractor, interval method,
simulation helper, or test fixture changed. This slice changes the documentation
gate that controls which existing surfaces can be admitted to Phase 18
simulation grids.

## Files Changed

- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/34-validation-debt-register.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-222659-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/46-pre-simulation-readiness-matrix.md docs/design/41-phase-18-simulation-programme.md docs/design/34-validation-debt-register.md NEWS.md ROADMAP.md
rg -n "Slice 291|evidence-ledger gate|Rose/Fisher|simulation status|admitted named surfaces|failure-ledger only|first-slice" NEWS.md ROADMAP.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md
rg -n "comprehensive all-feature|advertised.*implemented|animal.*admit|relmat.*admit|rho12.*random-effect layer|known sampling covariance.*latent" docs/design/46-pre-simulation-readiness-matrix.md docs/design/41-phase-18-simulation-programme.md docs/design/34-validation-debt-register.md README.md vignettes/model-map.Rmd
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
rg -n "Slice 291|evidence-ledger gate|Rose/Fisher|simulation status|admitted named surfaces|failure-ledger only|first-slice" NEWS.md ROADMAP.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 291 pre-simulation evidence ledger" --next "stage, commit, push, and open draft PR"
```

All checks passed. The final `first-slice` hits are older historical NEWS and
ROADMAP lines, not new Slice 291 wording.

## Tests Of The Tests

No executable tests changed. The closeout check is the gate scan: it would have
flagged a new global admission claim, an animal or `relmat()` fitted-grid claim,
or a new `rho12` random-effect-layer claim in the touched design docs.

## Consistency Audit

The new gate uses the same status vocabulary added in Slice 290. It keeps
residual `rho12`, known sampling covariance `V`, group-level covariance,
phylogenetic covariance, and spatial covariance as separate layers. It admits
named fitted surfaces only, keeps opt-in controls as stress cells rather than
scalability proof, and keeps reserved/planned neighbours in the failure ledger
until their own likelihood, tests, diagnostics, documentation, simulation
status, and after-task evidence exist.

## What Did Not Go Smoothly

The first wording pass risked sounding like a global signoff. The final text
says the result is conditional: current evidence can start Phase 18 on admitted
named surfaces, but it does not support a comprehensive all-feature grid.

## Team Learning

Ada kept the slice as a gate and ledger rather than a simulation launch. Fisher
checked that admission depends on evidence, not enthusiasm. Rose checked stale
status language and overclaim risk. Pat checked that a report writer can follow
the public-row to evidence-row path. Darwin checked that blocked model classes
remain visible instead of disappearing from the story. Grace confirmed formatting,
pkgdown, and whitespace checks. No spawned subagents were used.

## Known Limitations

The gate does not run simulations or prove operating characteristics. It also
does not update individual DGP files. The next Phase 18 slice still needs to
choose a specific admitted surface and cite the gate, validation-debt register,
and after-task evidence before running any comprehensive grid.

## Next Actions

Start Slice 292 only as a design blueprint for the first comprehensive
simulation wave. Keep the first wave as named admitted surfaces, with planned
or blocked neighbours reported through the failure ledger rather than simulated
as fitted paths.
